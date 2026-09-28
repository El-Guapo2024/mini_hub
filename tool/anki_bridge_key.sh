#!/usr/bin/env bash
# Names a build of the Anki bridge by everything that goes into the binary:
# the pinned Anki commit, the bridge's source, and the script that builds it.
# The Anki bridge workflows publish under this name and app builds download
# by it, so any change to those builds a new one and nothing else does.
#
#   tool/anki_bridge_key.sh           # iOS (the default, and the original)
#   tool/anki_bridge_key.sh android   # Android
#
# Each platform hashes only its own build script, so a change to how Android
# is built does not send iOS to a 90-minute macOS rebuild, or back.
set -euo pipefail
cd "$(dirname "$0")/.."
case "${1:-ios}" in
  ios) script=tool/build_anki_bridge.sh ;;
  android) script=tool/build_anki_bridge_android.sh ;;
  *) echo "usage: $0 [ios|android]" >&2 && exit 2 ;;
esac
cat native/anki_bridge/ANKI_COMMIT \
  native/anki_bridge/Cargo.toml \
  native/anki_bridge/src/lib.rs \
  "$script" |
  shasum -a 256 | cut -c1-16
