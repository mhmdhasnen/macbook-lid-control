#!/bin/bash
set -e

#
# LidController — Full Install Script
# Run with: sudo ./install.sh
#
# This script:
#   1. Kills any running LidController instances
#   2. Builds the app from source
#   3. Installs to /Applications
#   4. Sets up a sudoers rule so pmset doesn't prompt for password
#   5. Resets the menu bar cache
#   6. Launches the app
#

APP_NAME="LidController"
BUNDLE_DIR="${APP_NAME}.app"
INSTALL_DIR="/Applications"
SUDOERS_FILE="/etc/sudoers.d/lidcontroller"

# ── Must run as root ──────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo:"
    echo "  sudo ./install.sh"
    exit 1
fi

CURRENT_USER="${SUDO_USER:-$USER}"

echo "==> Installing ${APP_NAME} for user: ${CURRENT_USER}"
echo ""

# ── 1. Stop any running instances ─────────────────────────────────
echo "Step 1: Stopping existing ${APP_NAME}..."
pkill -9 -f "${APP_NAME}" 2>/dev/null || true
sleep 1

# ── 2. Build ──────────────────────────────────────────────────────
echo "Step 2: Building..."
cd "$(dirname "$0")"
sudo -u "${CURRENT_USER}" bash ./build.sh

# ── 3. Install to /Applications ──────────────────────────────────
echo "Step 3: Installing to ${INSTALL_DIR}..."
rm -rf "${INSTALL_DIR}/${BUNDLE_DIR}"
cp -R "${BUNDLE_DIR}" "${INSTALL_DIR}/"
chown -R "${CURRENT_USER}:staff" "${INSTALL_DIR}/${BUNDLE_DIR}"

# ── 4. Set up sudoers rule for pmset ─────────────────────────────
echo "Step 4: Setting up permissions (no password needed for power settings)..."
echo "${CURRENT_USER} ALL=(root) NOPASSWD: /usr/bin/pmset" > "${SUDOERS_FILE}"
chmod 0440 "${SUDOERS_FILE}"
chown root:wheel "${SUDOERS_FILE}"

# Validate the sudoers file — remove if invalid to avoid locking the user out
if ! visudo -c -f "${SUDOERS_FILE}" >/dev/null 2>&1; then
    echo "  WARNING: sudoers file invalid — removing for safety."
    rm -f "${SUDOERS_FILE}"
    echo "  You will still be prompted for your password when changing settings."
else
    echo "  Password-free pmset: OK"
fi

# ── 5. Reset menu bar cache ──────────────────────────────────────
echo "Step 5: Resetting menu bar..."
killall SystemUIServer 2>/dev/null || true
sleep 2

# ── 6. Clean up build artifact from repo ─────────────────────────
rm -rf "${BUNDLE_DIR}"

# ── 7. Launch ─────────────────────────────────────────────────────
echo "Step 6: Launching ${APP_NAME}..."
sudo -u "${CURRENT_USER}" open "${INSTALL_DIR}/${BUNDLE_DIR}"

echo ""
echo "Done! ${APP_NAME} is installed and running."
echo "Look for the laptop icon in your menu bar."
echo ""
echo "To uninstall later:"
echo "  sudo rm -rf ${INSTALL_DIR}/${BUNDLE_DIR} ${SUDOERS_FILE}"
