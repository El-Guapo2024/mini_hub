"""Upload the signed app bundle to Google Play and release it on a track.

Uploading and releasing are one edit here, where on Apple's side they are two
jobs: Play processes a bundle inside the upload call, so there is nothing to
wait for between them, and a bundle attached to no track reaches nobody --
the same lesson as TestFlight's build 5.

The internal track is the default: up to 100 testers named by email in Play
Console, no review, installable within minutes. Closed, open and production
tracks go through Google's review, which is Google's timing.

Environment (plus those in play_api.py):
  AAB_PATH             the bundle, e.g. build/app/outputs/bundle/release/app-release.aab
  PLAY_TRACK           internal (default), alpha, beta or production
  PLAY_RELEASE_STATUS  completed (default), or draft -- see below
  PLAY_RELEASE_NAME    what Play Console lists the release as, e.g. "1.0.0 (42)"
"""

import os
from pathlib import Path

from play_api import PACKAGE, UPLOAD, PlayError, call, commit, discard, open_edit

AAB = Path(os.environ["AAB_PATH"])
TRACK = os.environ.get("PLAY_TRACK", "internal").strip() or "internal"
STATUS = os.environ.get("PLAY_RELEASE_STATUS", "completed").strip() or "completed"
NAME = os.environ.get("PLAY_RELEASE_NAME", "").strip()

if STATUS not in ("completed", "draft"):
    raise SystemExit(f"PLAY_RELEASE_STATUS must be completed or draft, not {STATUS!r}")


def main() -> None:
    size = AAB.stat().st_size
    print(f"{PACKAGE}: uploading {AAB.name} ({size / 1e6:.1f} MB) for the {TRACK} track")
    edit = open_edit()
    try:
        bundle = call(
            "POST",
            f"/edits/{edit}/bundles",
            data=AAB.read_bytes(),
            content_type="application/octet-stream",
            base=UPLOAD,
            query="uploadType=media",
        )
        version = str(bundle["versionCode"])
        print(f"uploaded version code {version}")

        release = {"versionCodes": [version], "status": STATUS}
        if NAME:
            release["name"] = NAME
        call("PUT", f"/edits/{edit}/tracks/{TRACK}", {"track": TRACK, "releases": [release]})
        commit(edit)
    except PlayError as e:
        discard(edit)
        if "draft app" in e.body:
            raise SystemExit(
                "Play will only take a draft release until the app's first release has\n"
                "been rolled out from Play Console. Either roll that one out by hand, or\n"
                "run this again with the release status set to draft and roll it out\n"
                "from the Console. docs/shipping.md, 'The first upload'.\n\n"
                f"{e}"
            )
        if "version code" in e.body.lower() and "already been used" in e.body.lower():
            raise SystemExit(
                "Play has already seen this version code. It is the workflow's run number,\n"
                "which only goes up; a re-run of the same run reuses it. Start a new run.\n\n"
                f"{e}"
            )
        raise SystemExit(str(e))

    print(f"version code {version} is on the {TRACK} track ({STATUS})")


if __name__ == "__main__":
    main()
