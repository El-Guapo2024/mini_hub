"""Fill in everything App Store Connect asks for before 1.0 can be submitted.

The listing text is not invented here: it is the text in docs/app-store.md,
which was written against the code and checked. This script only puts it where
Apple can see it, so the two cannot drift by being retyped into a web form.

What it does NOT do is submit. Attaching metadata is reversible; submitting is
a declaration made under a developer account, and that stays a human's to make.

Two modes, and inspect is the default on purpose:

    MODE=inspect   read the live state and print it, change nothing
    MODE=apply     write the listing, attach the build, set the age rating

Apple's age rating declaration has changed shape between API versions, and a
payload with an attribute this account's API does not know is rejected whole
with a 400 that reads like a broken script. So apply never sends a field it
has not first seen Apple report: the wanted values are intersected with the
attributes actually present on the live declaration, and anything left over is
printed rather than guessed at.

Environment:
  ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH, ASC_APP_ID
  MODE          inspect (default) or apply
  BUILD_VERSION optional; when set, that build is attached to the version
"""

import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path

import jwt

BASE = "https://api.appstoreconnect.apple.com/v1"

KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
KEY_PATH = Path(os.environ["ASC_KEY_PATH"])
APP_ID = os.environ["ASC_APP_ID"]
MODE = os.environ.get("MODE", "inspect").strip().lower()
BUILD_VERSION = os.environ.get("BUILD_VERSION", "").strip()

if MODE not in ("inspect", "apply"):
    raise SystemExit(f"MODE must be inspect or apply, not {MODE!r}")

# The locale the listing is written in. Apple keys every piece of text by
# locale, and an app with one language still has to say which.
LOCALE = "en-US"

# ---------------------------------------------------------------------------
# The listing, verbatim from docs/app-store.md.

SUBTITLE = "Read Chinese, word by word"  # 26 chars; Apple's ceiling is 30

# 93 characters. Apple counts the commas and caps the field at 100.
KEYWORDS = (
    "chinese,mandarin,reader,epub,hsk,pinyin,dictionary,"
    "cedict,anki,flashcards,learn chinese,study"
)

PRIVACY_POLICY_URL = (
    "https://gist.github.com/El-Guapo2024/4cc6c5daef50907725e8fe430ab94987"
)

DESCRIPTION = """\
An interlinear reader for Chinese.

Open a Chinese EPUB and read it the way you actually read: tap any word for \
its pinyin and meaning, straight from the CC-CEDICT dictionary, offline and \
without leaving the page. Save the words worth keeping as flashcards as you go.

Have the page read aloud, following along word by word, at a pace you set.

Bring your own Claude API key and a reading companion sits beside you - ask \
why a sentence is built the way it is, what a particle is doing, what the \
writer implied but did not say. Connect an AnkiWeb account and the cards you \
save appear in Anki on all your devices.

The reader and the dictionary work offline and need no account. The companion \
and Anki sync are optional and use your own keys."""

# Nothing in Apple's questionnaire applies to this app: no violence, no mature
# or suggestive themes, no profanity, no gambling, no contests, no
# user-generated content shared between users, no unrestricted web access --
# the WebView renders local book files only and is pointed at about:blank when
# a book closes. See the reasoning in docs/app-store.md.
#
# The one honest wrinkle is that the reader opens whatever EPUB the user
# supplies, which is the same position as any ebook reader and is not what
# this questionnaire is asking about.
#
# Names differ by API version; only those Apple reports are sent.
AGE_RATING_NONE = {
    "alcoholTobaccoOrDrugUseOrReferences": "NONE",
    "contests": "NONE",
    "gamblingSimulated": "NONE",
    "horrorOrFearThemes": "NONE",
    "matureOrSuggestiveThemes": "NONE",
    "medicalOrTreatmentInformation": "NONE",
    "profanityOrCrudeHumor": "NONE",
    "sexualContentGraphicAndNudity": "NONE",
    "sexualContentOrNudity": "NONE",
    "violenceCartoonOrFantasy": "NONE",
    "violenceRealistic": "NONE",
    "violenceRealisticProlongedGraphicOrSadistic": "NONE",
    "gambling": False,
    "unrestrictedWebAccess": False,
    "kidsAgeBand": None,
    "seventeenPlus": False,
    "loleAppEnabled": False,
}


def call(method: str, path: str, body=None):
    now = int(time.time())
    token = jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"},
        KEY_PATH.read_text(),
        algorithm="ES256",
        headers={"kid": KEY_ID, "typ": "JWT"},
    )
    req = urllib.request.Request(
        f"{BASE}{path}",
        method=method,
        data=json.dumps(body).encode() if body else None,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raise SystemExit(f"HTTP {e.code} on {method} {path}\n{e.read().decode()}")


def patch(kind: str, ident: str, attributes: dict):
    """Write, or say what would be written."""
    if MODE == "inspect":
        print(f"  would PATCH {kind}/{ident}: {sorted(attributes)}")
        return
    call(
        "PATCH",
        f"/{kind}/{ident}",
        {"data": {"type": kind, "id": ident, "attributes": attributes}},
    )
    print(f"  set {sorted(attributes)}")


def editable(records, states, label):
    """The one record Apple will let us edit, or a readable failure."""
    for r in records:
        state = r["attributes"].get("appStoreState") or r["attributes"].get(
            "state", ""
        )
        if state in states:
            return r
    seen = ", ".join(
        f"{r['id']}={r['attributes'].get('appStoreState') or r['attributes'].get('state')}"
        for r in records
    )
    raise SystemExit(
        f"no editable {label}: nothing is in {'/'.join(states)}.\n"
        f"found: {seen or 'none at all'}\n"
        "A version already submitted or released cannot be edited; make a new "
        "version in App Store Connect first."
    )


EDITABLE = (
    "PREPARE_FOR_SUBMISSION",
    "DEVELOPER_REJECTED",
    "REJECTED",
    "METADATA_REJECTED",
    "INVALID_BINARY",
)

print(f"=== mode: {MODE} ===\n")

# --- the app-level listing: name, subtitle, privacy policy -----------------

infos = call("GET", f"/apps/{APP_ID}/appInfos")["data"]
info = editable(infos, EDITABLE, "appInfo")
print(f"appInfo {info['id']} ({info['attributes'].get('appStoreState')})")

for loc in call("GET", f"/appInfos/{info['id']}/appInfoLocalizations")["data"]:
    if loc["attributes"]["locale"] != LOCALE:
        continue
    a = loc["attributes"]
    print(f"  {LOCALE}: name={a.get('name')!r} subtitle={a.get('subtitle')!r}")
    print(f"           privacyPolicyUrl={a.get('privacyPolicyUrl')!r}")
    patch(
        "appInfoLocalizations",
        loc["id"],
        {"subtitle": SUBTITLE, "privacyPolicyUrl": PRIVACY_POLICY_URL},
    )

# --- the age rating --------------------------------------------------------
#
# Unset, this blocks submission outright. Sent whole, an unknown attribute
# rejects the lot -- so send only what Apple already reports.

rating = call("GET", f"/appInfos/{info['id']}/ageRatingDeclaration").get("data")
if not rating:
    print("\nno ageRatingDeclaration on this appInfo")
else:
    live = rating["attributes"]
    print(f"\nageRatingDeclaration {rating['id']}")
    # Values, not just names. Half these fields are booleans and half are
    # NONE/INFREQUENT_OR_MILD/FREQUENT_OR_INTENSE enums, and there is no way
    # to tell which from the name: sending false where an enum belongs
    # rejects the whole payload. The live value gives away the type.
    print("  Apple reports:")
    for k in sorted(live):
        print(f"    {k} = {live[k]!r}")
    known = {k: v for k, v in AGE_RATING_NONE.items() if k in live}
    unknown = sorted(set(AGE_RATING_NONE) - set(live))
    extra = sorted(set(live) - set(AGE_RATING_NONE))
    if unknown:
        print(f"  not on this API version, not sent: {unknown}")
    if extra:
        print(f"  Apple has fields we say nothing about: {extra}")
    patch("ageRatingDeclarations", rating["id"], known)

# --- the version listing: description and keywords -------------------------

versions = call("GET", f"/apps/{APP_ID}/appStoreVersions?limit=50")["data"]
version = editable(versions, EDITABLE, "appStoreVersion")
va = version["attributes"]
print(
    f"\nappStoreVersion {version['id']} "
    f"({va.get('versionString')}, {va.get('appStoreState')})"
)

for loc in call(
    "GET", f"/appStoreVersions/{version['id']}/appStoreVersionLocalizations"
)["data"]:
    if loc["attributes"]["locale"] != LOCALE:
        continue
    a = loc["attributes"]
    have = (a.get("description") or "").strip()
    print(f"  {LOCALE}: description={len(have)} chars, keywords={a.get('keywords')!r}")
    patch(
        "appStoreVersionLocalizations",
        loc["id"],
        {"description": DESCRIPTION, "keywords": KEYWORDS},
    )

# --- the build ------------------------------------------------------------
#
# A version with no build attached cannot be submitted, and the build is the
# one thing here that is not text: it has to have finished processing.

if not BUILD_VERSION:
    print("\nBUILD_VERSION not set -- leaving the attached build alone")
else:
    builds = call(
        "GET", f"/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=200"
    )["data"]
    match = next(
        (b for b in builds if b["attributes"]["version"] == BUILD_VERSION), None
    )
    if not match:
        newest = ", ".join(
            f"{b['attributes']['version']}={b['attributes']['processingState']}"
            for b in builds[:5]
        )
        raise SystemExit(
            f"\nno build {BUILD_VERSION} on this app.\n"
            f"newest: {newest or 'no builds at all'}\n"
            "A build Apple discards during ingest never appears here in any "
            "state, and the reason goes out by email rather than to this API. "
            "Check the account holder's mailbox before rebuilding."
        )
    state = match["attributes"]["processingState"]
    print(f"\nbuild {BUILD_VERSION}: {state}")
    if state != "VALID":
        raise SystemExit(
            f"build {BUILD_VERSION} is {state}, not VALID -- it cannot be "
            "attached until Apple finishes processing it."
        )
    if MODE == "inspect":
        print(f"  would attach build {match['id']}")
    else:
        call(
            "PATCH",
            f"/appStoreVersions/{version['id']}/relationships/build",
            {"data": {"type": "builds", "id": match["id"]}},
        )
        print(f"  attached build {BUILD_VERSION}")

print(
    "\n=== done ===\n"
    "Screenshots are not set here: the API wants each image uploaded in "
    "several steps against a reservation, and they are already captured in\n"
    "  ~/Documents/TheMiniHub App Store/screenshots/\n"
    "Drag those in, then press Submit for Review yourself -- that button is "
    "a declaration under your developer account, and no script should press "
    "it for you."
)
