"""Hand the build just uploaded to every test group that should have it.

Uploading is not releasing. A build that finishes processing sits in App Store
Connect visible to nobody until it is attached to a group, so without this step
every merge would reach Apple and no iPad.

Waits for processing, because a build cannot be attached until it is VALID.
That takes a few minutes and is Apple's to do.

Environment:
  ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH, ASC_APP_ID, BUILD_VERSION
  ASC_GROUPS -- comma-separated group names, default "Internal,Public"

An internal group reaches whoever is on the App Store Connect account; the
external one reaches everybody else, and only once Apple's beta review has
passed the build. Attaching to both here is what stops external testers
quietly stalling on whichever build was last attached by hand.
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
VERSION = os.environ["BUILD_VERSION"]
GROUP_NAMES = [
    n.strip()
    for n in os.environ.get("ASC_GROUPS", "Internal,Public").split(",")
    if n.strip()
]

# Ten minutes, and no longer. This once waited forty-five, on the theory that
# a build missing from the API was a slow build worth waiting for. It is not:
# a build Apple discards during ingest never appears in the API in any state,
# so the wait could only ever end in failure. Builds 10 to 14 were each
# discarded for ITMS-90683 and each held a macOS runner for the full
# three quarters of an hour -- about 510 billed minutes apiece at the 10x
# macOS multiplier, which spent a month's quota waiting for five builds that
# did not exist. Waiting longer cannot rescue a build; it only costs money.
DEADLINE = 10 * 60
POLL = 20


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
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raise SystemExit(f"HTTP {e.code} on {method} {path}\n{e.read().decode()}")


def recent_builds():
    """Newest builds first.

    Sorted and asked for by the hundred rather than taking whatever twenty the
    API felt like returning: unsorted, a build falls out of the window as soon
    as the app has enough history, and a build that is merely out of view is
    indistinguishable from one that was never uploaded.
    """
    return call(
        "GET",
        f"/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=200",
    )["data"]


def build_now():
    for b in recent_builds():
        if b["attributes"]["version"] == VERSION:
            return b
    return None


started = time.time()
build = None
while time.time() - started < DEADLINE:
    seen = recent_builds()
    build = next((b for b in seen if b["attributes"]["version"] == VERSION), None)
    state = build["attributes"]["processingState"] if build else "not visible yet"
    # What else is there, when the one we want is not. "Not visible yet" on its
    # own cannot tell a slow build from a lookup that is looking in the wrong
    # place, and that ambiguity cost two uploads.
    if not build:
        others = ", ".join(
            f"{b['attributes']['version']}={b['attributes']['processingState']}"
            for b in seen[:5]
        )
        state += f" (newest on the app: {others or 'no builds at all'})"
    print(f"build {VERSION}: {state}", flush=True)
    if build and state == "VALID":
        break
    if build and state in ("INVALID", "FAILED"):
        raise SystemExit(f"build {VERSION} came back {state} -- App Store Connect says why")
    time.sleep(POLL)
else:
    raise SystemExit(
        f"build {VERSION} was still not VALID after {DEADLINE // 60} minutes.\n"
        "\n"
        "If it never became visible at all, Apple discarded it while "
        "processing and it will never appear here. The reason is sent by "
        "email and by nothing this API can see, so check the Apple "
        "developer account holder's mailbox -- not necessarily the address "
        "you read day to day -- for a message from App Store Connect titled "
        "'Action needed: The uploaded build ... has one or more issues'. It "
        "names an ITMS code, which is the actual cause. Do that before "
        "changing anything or rebuilding: five builds were lost to guessing "
        "at this while the answer sat in an inbox."
    )

all_groups = {
    g["attributes"]["name"]: g
    for g in call("GET", f"/betaGroups?filter[app]={APP_ID}&limit=50")["data"]
}

missing = [n for n in GROUP_NAMES if n not in all_groups]
if missing:
    raise SystemExit(
        f"no beta group called {', '.join(missing)} on this app -- "
        f"it has {', '.join(sorted(all_groups)) or 'none'}"
    )

for name in GROUP_NAMES:
    group = all_groups[name]
    already = [b["id"] for b in call("GET", f"/betaGroups/{group['id']}/builds")["data"]]
    if build["id"] in already:
        print(f"build {VERSION} is already with {name}")
        continue

    call(
        "POST",
        f"/betaGroups/{group['id']}/relationships/builds",
        {"data": [{"type": "builds", "id": build["id"]}]},
    )
    print(f"build {VERSION} released to {name}")
