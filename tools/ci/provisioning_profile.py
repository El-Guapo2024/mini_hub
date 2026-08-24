"""Find or create the App Store provisioning profile, and install it.

Run on CI before signing. Prints the profile's name on stdout, which is what
the export options plist needs in order to sign manually.

Manual signing, rather than letting Xcode fetch a profile itself: Xcode's
automatic signing wants a cloud-managed distribution certificate, and an App
Store Connect API key is not allowed to use one. It fails with "Cloud signing
permission error", and then with "No profiles were found" as a consequence.

Doing it here instead of committing a profile as a secret means there is no
profile to expire. Apple issues them for a year; this asks for the current one
every build, and makes a new one if the account has none.

Environment:
  ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH, BUNDLE_ID
"""

import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import jwt

BASE = "https://api.appstoreconnect.apple.com/v1"
PROFILE_TYPE = "IOS_APP_STORE"

KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
KEY_PATH = Path(os.environ["ASC_KEY_PATH"])
BUNDLE_ID = os.environ["BUNDLE_ID"]

# Named after the bundle it signs, so a second app in this account does not
# collide with it and nobody has to guess which profile is which.
PROFILE_NAME = f"CI App Store {BUNDLE_ID}"


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
        # Apple's body is the only part that says what was actually wrong.
        raise SystemExit(f"HTTP {e.code} on {method} {path}\n{e.read().decode()}")


def log(message: str) -> None:
    # stdout is the profile name and nothing else, so the caller can capture it.
    print(message, file=sys.stderr)


def find() -> dict | None:
    for p in call("GET", "/profiles?limit=200")["data"]:
        a = p["attributes"]
        if a["name"] == PROFILE_NAME and a["profileType"] == PROFILE_TYPE:
            # An expired or otherwise unusable profile is worse than none: it
            # signs nothing and hides the fact that it needs replacing.
            if a.get("profileState") != "ACTIVE":
                log(f"found {PROFILE_NAME}, state {a.get('profileState')} -- deleting")
                call("DELETE", f"/profiles/{p['id']}")
                return None
            return p
    return None


def create() -> dict:
    bundles = call("GET", f"/bundleIds?filter[identifier]={BUNDLE_ID}")["data"]
    if not bundles:
        raise SystemExit(f"{BUNDLE_ID} is not registered as an App ID")

    certs = [
        c
        for c in call("GET", "/certificates?limit=200")["data"]
        if c["attributes"]["certificateType"] == "DISTRIBUTION"
    ]
    if not certs:
        raise SystemExit(
            "no distribution certificate in this account -- the profile has to "
            "name one, and it must be the same certificate the build signs with"
        )

    log(f"creating {PROFILE_NAME}")
    return call(
        "POST",
        "/profiles",
        {
            "data": {
                "type": "profiles",
                "attributes": {"name": PROFILE_NAME, "profileType": PROFILE_TYPE},
                "relationships": {
                    "bundleId": {"data": {"type": "bundleIds", "id": bundles[0]["id"]}},
                    "certificates": {
                        "data": [{"type": "certificates", "id": c["id"]} for c in certs]
                    },
                },
            }
        },
    )["data"]


profile = find() or create()

# Fetched fresh either way: the content is only included on some responses.
content = call("GET", f"/profiles/{profile['id']}")["data"]["attributes"][
    "profileContent"
]

directory = Path.home() / "Library/MobileDevice/Provisioning Profiles"
directory.mkdir(parents=True, exist_ok=True)
installed = directory / f"{PROFILE_NAME}.mobileprovision"
installed.write_bytes(base64.b64decode(content))
log(f"installed {installed} ({installed.stat().st_size} bytes)")

print(PROFILE_NAME)
