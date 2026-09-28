"""Put the Play Store listing where Google can see it: the text and the icon.

The text is docs/play-store.md's, copied here verbatim, for the same reason
app_store_metadata.py copies docs/app-store.md: retyped into a web form, the
two drift. Change it there and here together.

Two modes, and inspect is the default on purpose:

    MODE=inspect   read the live listing, print it and what apply would change
    MODE=apply     write the title, descriptions, contact email and icon

Neither submits anything for review or releases anything. What the API cannot
set -- the privacy policy URL, the data safety form, the content rating
questionnaire, target audience, the feature graphic and screenshots -- is
listed in docs/play-store.md with the answers to give, and is entered in Play
Console by hand.

Environment (plus those in play_api.py):
  MODE   inspect (default) or apply
"""

import os
from pathlib import Path

from play_api import PACKAGE, UPLOAD, PlayError, call, commit, discard, open_edit

MODE = os.environ.get("MODE", "inspect").strip().lower()
if MODE not in ("inspect", "apply"):
    raise SystemExit(f"MODE must be inspect or apply, not {MODE!r}")

ROOT = Path(__file__).resolve().parents[2]
ICON = ROOT / "android/play/icon-512.png"  # made by tools/android_icons.py

LANGUAGE = "en-US"

# ---------------------------------------------------------------------------
# The listing, verbatim from docs/play-store.md.

TITLE = "TheMiniHub"  # the App Store name; Play's ceiling is 30

SHORT_DESCRIPTION = (  # Play's ceiling is 80
    "Read Chinese books word by word, with a dictionary and a reading companion."
)

FULL_DESCRIPTION = """\
An interlinear reader for Chinese.

Open a Chinese EPUB and read it the way you actually read: tap any character \
for its pinyin and meaning, straight from the CC-CEDICT dictionary, offline and \
without leaving the page. Drag across a phrase to look up the whole run. Save \
the words worth keeping as flashcards as you go, with the sentence you met \
them in.

Have the page read aloud, following along word by word, at a pace you set.

Bring your own Claude API key and a reading companion sits beside you. Select \
a few words and it says what they mean in this sentence, not just what they \
can mean. Ask why a sentence is built the way it is, what a particle is doing, \
what the writer implied but did not say - by typing, or by holding the mic and \
asking out loud. Connect an AnkiWeb account and the cards you save appear in \
Anki on all your devices.

The reader and the dictionary work offline and need no account. The companion \
and Anki sync are optional and use your own keys. Speech recognition runs on \
the phone; audio never leaves it."""

CONTACT_EMAIL = "antoniotwin_luera@hotmail.com"  # the privacy policy's contact

LIMITS = {"title": 30, "shortDescription": 80, "fullDescription": 4000}
WANTED_LISTING = {
    "title": TITLE,
    "shortDescription": SHORT_DESCRIPTION,
    "fullDescription": FULL_DESCRIPTION,
}

for field, limit in LIMITS.items():
    if len(WANTED_LISTING[field]) > limit:
        raise SystemExit(f"{field} is {len(WANTED_LISTING[field])} characters; Play allows {limit}")


def show(label: str, have, want) -> bool:
    same = have == want
    mark = "  same" if same else "CHANGE"
    shown = (have or "").replace("\n", " ")
    print(f"[{mark}] {label}: {shown[:100]}{'...' if len(shown) > 100 else ''}")
    return not same


def main() -> None:
    edit = open_edit()
    try:
        try:
            listing = call("GET", f"/edits/{edit}/listings/{LANGUAGE}")
        except PlayError as e:
            if e.status != 404:
                raise
            listing = {}
        details = call("GET", f"/edits/{edit}/details")
        icons = call("GET", f"/edits/{edit}/listings/{LANGUAGE}/icon").get("images", [])

        print(f"{PACKAGE}, {LANGUAGE}")
        changed = False
        for field, want in WANTED_LISTING.items():
            changed |= show(field, listing.get(field), want)
        changed |= show("contactEmail", details.get("contactEmail"), CONTACT_EMAIL)
        print(f"[{'  same' if icons else 'CHANGE'}] icon: {len(icons)} uploaded")

        # What the API cannot set, counted so the gap is visible.
        for kind in ("featureGraphic", "phoneScreenshots", "sevenInchScreenshots", "tenInchScreenshots"):
            images = call("GET", f"/edits/{edit}/listings/{LANGUAGE}/{kind}").get("images", [])
            print(f"[  info] {kind}: {len(images)} uploaded (entered in Play Console)")

        if MODE == "inspect":
            discard(edit)
            print("\ninspect: nothing written")
            return

        call("PUT", f"/edits/{edit}/listings/{LANGUAGE}", {"language": LANGUAGE, **WANTED_LISTING})
        call("PATCH", f"/edits/{edit}/details", {"contactEmail": CONTACT_EMAIL})
        # Replaced rather than added to: Play keeps one icon, and uploading
        # beside an old one is refused.
        call("DELETE", f"/edits/{edit}/listings/{LANGUAGE}/icon")
        call(
            "POST",
            f"/edits/{edit}/listings/{LANGUAGE}/icon",
            data=ICON.read_bytes(),
            content_type="image/png",
            base=UPLOAD,
            query="uploadType=media",
        )
        commit(edit)
        print("\napply: listing written" + ("" if changed else " (it already matched)"))
    except PlayError as e:
        discard(edit)
        raise SystemExit(str(e))


if __name__ == "__main__":
    main()
