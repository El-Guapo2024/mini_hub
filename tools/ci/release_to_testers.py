"""Hand the build just uploaded to the internal test group.

Uploading is not releasing. A build that finishes processing sits in App Store
Connect visible to nobody until it is attached to a group, so without this step
every merge would reach Apple and no iPad.

Waits for processing, because a build cannot be attached until it is VALID.
That takes a few minutes and is Apple's to do.

Environment:
  ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH, ASC_APP_ID, BUILD_VERSION
  ASC_GROUP -- group name, default "Internal"
"""

import json
import os
import sys
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
GROUP_NAME = os.environ.get("ASC_GROUP", "Internal")

# Apple usually takes two or three minutes. Fifteen is generous rather than
# hopeful; past that something is wrong and saying so beats waiting longer.
DEADLINE = 15 * 60
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


def build_now():
    for b in call("GET", f"/builds?filter[app]={APP_ID}&limit=20")["data"]:
        if b["attributes"]["version"] == VERSION:
            return b
    return None


started = time.time()
build = None
while time.time() - started < DEADLINE:
    build = build_now()
    state = build["attributes"]["processingState"] if build else "not visible yet"
    print(f"build {VERSION}: {state}", flush=True)
    if build and state == "VALID":
        break
    if build and state in ("INVALID", "FAILED"):
        raise SystemExit(f"build {VERSION} came back {state} -- App Store Connect says why")
    time.sleep(POLL)
else:
    raise SystemExit(f"build {VERSION} was still not VALID after {DEADLINE // 60} minutes")

groups = [
    g
    for g in call("GET", f"/betaGroups?filter[app]={APP_ID}&limit=50")["data"]
    if g["attributes"]["name"] == GROUP_NAME
]
if not groups:
    raise SystemExit(f"no beta group called {GROUP_NAME} on this app")
group = groups[0]

already = [b["id"] for b in call("GET", f"/betaGroups/{group['id']}/builds")["data"]]
if build["id"] in already:
    print(f"build {VERSION} is already with {GROUP_NAME}")
    sys.exit(0)

call(
    "POST",
    f"/betaGroups/{group['id']}/relationships/builds",
    {"data": [{"type": "builds", "id": build["id"]}]},
)
print(f"build {VERSION} released to {GROUP_NAME}")
