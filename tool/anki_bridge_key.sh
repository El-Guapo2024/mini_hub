#!/usr/bin/env bash
# Names a build of the Anki bridge by everything that goes into the binary:
# the pinned Anki commit, the bridge's source, and the script that builds it.
# The Anki bridge workflow publishes under this name and app builds download
# by it, so any change to those builds a new one and nothing else does.
set -euo pipefail
cd "$(dirname "$0")/.."
cat native/anki_bridge/ANKI_COMMIT \
  native/anki_bridge/Cargo.toml \
  native/anki_bridge/src/lib.rs \
  tool/build_anki_bridge.sh |
  shasum -a 256 | cut -c1-16
