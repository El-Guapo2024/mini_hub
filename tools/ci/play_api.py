"""The Google Play Developer API, over plain HTTP, for the two Play scripts.

A service account signs a JWT, trades it for an hour's access token, and every
change is made inside an "edit": opened, changed, then committed as one. An
edit that is never committed changes nothing, which is what makes inspecting
safe.

The same shape as the App Store Connect scripts beside it -- urllib and pyjwt,
no Google client library -- so there is one way of talking to a store in this
repository, not two.

Environment:
  PLAY_SERVICE_ACCOUNT  path to the service account's JSON key
  PLAY_PACKAGE          the application id, e.g. com.juanluera.minihub
"""

import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

import jwt

PACKAGE = os.environ.get("PLAY_PACKAGE", "com.juanluera.minihub")
SCOPE = "https://www.googleapis.com/auth/androidpublisher"
BASE = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE}"
UPLOAD = f"https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/{PACKAGE}"

_token = None


def token() -> str:
    """An access token for the service account, made once per run."""
    global _token
    if _token:
        return _token
    account = json.loads(Path(os.environ["PLAY_SERVICE_ACCOUNT"]).read_text())
    now = int(time.time())
    assertion = jwt.encode(
        {
            "iss": account["client_email"],
            "scope": SCOPE,
            "aud": account["token_uri"],
            "iat": now,
            "exp": now + 3600,
        },
        account["private_key"],
        algorithm="RS256",
        headers={"kid": account["private_key_id"]},
    )
    body = urllib.parse.urlencode(
        {
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": assertion,
        }
    ).encode()
    req = urllib.request.Request(account["token_uri"], data=body, method="POST")
    try:
        with urllib.request.urlopen(req) as r:
            _token = json.loads(r.read())["access_token"]
    except urllib.error.HTTPError as e:
        raise SystemExit(f"Google refused the service account: HTTP {e.code}\n{e.read().decode()}")
    return _token


class PlayError(Exception):
    def __init__(self, status: int, method: str, url: str, body: str):
        super().__init__(f"HTTP {status} on {method} {url}\n{body}")
        self.status = status
        self.body = body


def call(method: str, path: str, body=None, *, data: bytes = None,
         content_type: str = "application/json", base: str = BASE, query: str = ""):
    url = f"{base}{path}{'?' + query if query else ''}"
    payload = data if data is not None else (json.dumps(body).encode() if body is not None else None)
    req = urllib.request.Request(
        url,
        method=method,
        data=payload,
        headers={"Authorization": f"Bearer {token()}", "Content-Type": content_type},
    )
    try:
        # Long enough for a 170 MB bundle over a runner's uplink.
        with urllib.request.urlopen(req, timeout=900) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raise PlayError(e.code, method, url, e.read().decode())


def open_edit() -> str:
    try:
        return call("POST", "/edits", {})["id"]
    except PlayError as e:
        if e.status == 404:
            raise SystemExit(
                f"Play does not know {PACKAGE} yet, or this service account cannot see it.\n"
                "The app has to be created in Play Console, and its first bundle uploaded there\n"
                "by hand, before the API will talk about it; and the service account has to be\n"
                "invited under Users and permissions. docs/shipping.md has the steps.\n\n"
                f"{e}"
            )
        raise


def commit(edit: str) -> None:
    call("POST", f"/edits/{edit}:commit")


def discard(edit: str) -> None:
    try:
        call("DELETE", f"/edits/{edit}")
    except PlayError:
        # An edit left open expires on its own; failing to tidy it is not news.
        pass
