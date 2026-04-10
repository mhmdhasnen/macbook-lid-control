#!/bin/bash
set -e

# Run the build script first to ensure we have the latest version compiled
echo "Step 1: Building the application..."
if [ ! -f "build.sh" ]; then
    echo "Error: build.sh not found in the current directory."
    exit 1
fi
./build.sh

APP_NAME="LidController"
BUNDLE_DIR="${APP_NAME}.app"
INSTALL_DIR="/Applications"

echo ""
echo "Step 2: Installing ${APP_NAME} to ${INSTALL_DIR}..."

# Check if the app already exists in Applications and remove it to avoid permission conflicts
if [ -d "${INSTALL_DIR}/${BUNDLE_DIR}" ]; then
    echo "Found an existing installation. Removing older version..."
    rm -rf "${INSTALL_DIR}/${BUNDLE_DIR}"
fi

# Copy the app to Applications
cp -R "${BUNDLE_DIR}" "${INSTALL_DIR}/"

echo "Success! The application has been installed."
echo ""
echo "You can now launch ${APP_NAME} from your Applications folder or via Spotlight."

# Ask user if they want to launch the app now
read -p "Would you like to open it now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "${INSTALL_DIR}/${BUNDLE_DIR}"
fi
