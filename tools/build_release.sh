#!/usr/bin/env bash
# Builds the signed release of Updraft: an .aab for Google Play and an .apk to share directly.
#   bash tools/build_release.sh
# The signing key lives outside the repo, in %APPDATA%\Godot\keystores (updraft-release.keystore,
# and updraft-release-password.txt next to it). Nothing secret is written into the project:
# Godot reads the key from environment variables for this build only.
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT=/c/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe
KEYS="$APPDATA/Godot/keystores"
PASSWORD_FILE="$KEYS/updraft-release-password.txt"
if [ ! -f "$KEYS/updraft-release.keystore" ] || [ ! -f "$PASSWORD_FILE" ]; then
	echo "No release key in $KEYS (see docs/release.md)." >&2
	exit 1
fi
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KEYS/updraft-release.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=updraft
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(sed -n 's/^password: //p' "$PASSWORD_FILE" | tr -d '\r')"
if [ -z "$GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD" ]; then
	echo "No 'password: ' line in $PASSWORD_FILE." >&2
	exit 1
fi
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD

mkdir -p build
"$GODOT" --headless --path . --export-release "Android" build/updraft.apk
"$GODOT" --headless --path . --export-release "Android AAB" build/updraft.aab
ls -l build/updraft.apk build/updraft.aab
