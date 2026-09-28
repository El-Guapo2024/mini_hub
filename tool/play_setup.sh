#!/usr/bin/env bash
# Google Play setup for El-Guapo2024/mini_hub, the parts that can be scripted.
# Run on your own machine, signed in with `gh auth login` as someone who can
# set the repository's secrets.
#
#   bash tool/play_setup.sh                          # upload key + its two secrets
#   bash tool/play_setup.sh ~/Downloads/play-sa.json # ...and the service account
#
# Run it with bash: pasted into zsh, the lines above are not comments.
#
# If ~/ws/secrets/android/ already holds upload-keystore.jks and its
# README.txt (unzip play-upload-key.zip there first), that key is used as it
# is. Otherwise a new one is made there, beside the Apple credentials as
# docs/shipping.md describes, with its password in the README.txt. Either
# way, it then sets:
#   ANDROID_UPLOAD_KEYSTORE           the keystore, base64
#   ANDROID_UPLOAD_KEYSTORE_PASSWORD  its password
#   GOOGLE_PLAY_SERVICE_ACCOUNT       the service account's JSON key, if given
#
# Safe to run again: an existing key is reused, never replaced. Replacing it
# after the first upload would mean asking Play support to accept a new one.
set -euo pipefail

REPO=El-Guapo2024/mini_hub
DIR="$HOME/ws/secrets/android"
KEY="$DIR/upload-keystore.jks"
NOTE="$DIR/README.txt"

command -v gh >/dev/null || { echo "gh not found: brew install gh, then gh auth login." >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "Sign in first: gh auth login" >&2; exit 1; }

mkdir -p "$DIR"
chmod 700 "$DIR"
if [[ -f "$KEY" ]]; then
  echo "Reusing the upload key already at $KEY"
  PASS="$(sed -n 's/^password: //p' "$NOTE")"
  [[ -n "$PASS" ]] || { echo "No password found in $NOTE" >&2; exit 1; }
else
  command -v keytool >/dev/null || { echo "keytool not found: install a JDK (brew install openjdk)." >&2; exit 1; }
  PASS="$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | cut -c1-28)"
  # PKCS12 has one password for the store and the key, which is why the
  # workflow reads one password secret for both.
  keytool -genkeypair -keystore "$KEY" -storetype PKCS12 \
    -keyalg RSA -keysize 2048 -validity 10000 -alias upload \
    -storepass "$PASS" -dname "CN=TheMiniHub upload key" >/dev/null
  cat > "$NOTE" <<EOF
Google Play upload key for com.juanluera.minihub (TheMiniHub)
file: upload-keystore.jks
alias: upload
password: $PASS

Keep a copy somewhere that is not this machine. If it is lost, Play support
can register a new upload key; Google holds the key that signs the app.
EOF
  chmod 600 "$KEY" "$NOTE"
  echo "Made the upload key at $KEY (password in $NOTE)"
fi

base64 < "$KEY" | tr -d '\n' | gh secret set ANDROID_UPLOAD_KEYSTORE --repo "$REPO"
printf '%s' "$PASS" | gh secret set ANDROID_UPLOAD_KEYSTORE_PASSWORD --repo "$REPO"
echo "Set ANDROID_UPLOAD_KEYSTORE and ANDROID_UPLOAD_KEYSTORE_PASSWORD"

if [[ -n "${1:-}" ]]; then
  python3 -c 'import json,sys; k=json.load(open(sys.argv[1])); assert k["type"]=="service_account", "not a service account key"' "$1"
  gh secret set GOOGLE_PLAY_SERVICE_ACCOUNT --repo "$REPO" < "$1"
  echo "Set GOOGLE_PLAY_SERVICE_ACCOUNT"
else
  echo "GOOGLE_PLAY_SERVICE_ACCOUNT not set: run again with the JSON key's path once you have it."
fi

echo
echo "Next: gh workflow run \"Google Play\" --repo $REPO --ref main -f upload=false"
