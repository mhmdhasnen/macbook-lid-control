#!/bin/bash
set -e

APP_NAME="LidController"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"
STAGING_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "${STAGING_DIR}"
}

trap cleanup EXIT

if [ ! -d "${APP_BUNDLE}" ]; then
    echo "Error: ${APP_BUNDLE} not found. Run ./build.sh first."
    exit 1
fi

cp -R "${APP_BUNDLE}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

rm -f "${DMG_NAME}"
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_NAME}" >/dev/null

echo "DMG created at ${DMG_NAME}"