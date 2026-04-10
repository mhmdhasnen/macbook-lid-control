#!/bin/bash
set -e

APP_NAME="LidController"
BUNDLE_DIR="${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
ICON_NAME="AppIcon"
ICON_DIR="Assets.xcassets/AppIcon.appiconset"

resolve_icon_source() {
    local candidate

    for candidate in \
        "${ICON_DIR}/icon_source.png" \
        "${ICON_DIR}/icon_source.jpg" \
        "${ICON_DIR}/icon_source.jpeg" \
        "${ICON_DIR}/icon_source.svg"
    do
        if [ -f "${candidate}" ]; then
            printf '%s\n' "${candidate}"
            return 0
        fi
    done

    echo "Error: no icon source found in ${ICON_DIR}. Expected icon_source.png, icon_source.jpg, icon_source.jpeg, or icon_source.svg." >&2
    exit 1
}

generate_app_icon() {
    local icon_source work_dir preview_dir rendered_png iconset_dir

    icon_source="$(resolve_icon_source)"

    work_dir="$(mktemp -d)"
    preview_dir="${work_dir}/preview"
    rendered_png="${work_dir}/icon_1024.png"
    iconset_dir="${work_dir}/${ICON_NAME}.iconset"

    mkdir -p "${preview_dir}" "${iconset_dir}"

    case "${icon_source}" in
        *.svg)
            qlmanage -t -s 1024 -o "${preview_dir}" "${icon_source}" >/dev/null 2>&1
            cp "${preview_dir}/$(basename "${icon_source}").png" "${rendered_png}"
            ;;
        *)
            sips -s format png -z 1024 1024 "${icon_source}" --out "${rendered_png}" >/dev/null
            ;;
    esac

    cp "${rendered_png}" "${ICON_DIR}/icon_1024x1024.png"

    sips -z 16 16     "${rendered_png}" --out "${iconset_dir}/icon_16x16.png" >/dev/null
    sips -z 32 32     "${rendered_png}" --out "${iconset_dir}/icon_16x16@2x.png" >/dev/null
    sips -z 32 32     "${rendered_png}" --out "${iconset_dir}/icon_32x32.png" >/dev/null
    sips -z 64 64     "${rendered_png}" --out "${iconset_dir}/icon_32x32@2x.png" >/dev/null
    sips -z 128 128   "${rendered_png}" --out "${iconset_dir}/icon_128x128.png" >/dev/null
    sips -z 256 256   "${rendered_png}" --out "${iconset_dir}/icon_128x128@2x.png" >/dev/null
    sips -z 256 256   "${rendered_png}" --out "${iconset_dir}/icon_256x256.png" >/dev/null
    sips -z 512 512   "${rendered_png}" --out "${iconset_dir}/icon_256x256@2x.png" >/dev/null
    sips -z 512 512   "${rendered_png}" --out "${iconset_dir}/icon_512x512.png" >/dev/null
    cp "${rendered_png}" "${iconset_dir}/icon_512x512@2x.png"

    iconutil -c icns "${iconset_dir}" -o "${RESOURCES_DIR}/${ICON_NAME}.icns"

    rm -rf "${work_dir}"
}

echo "Building ${APP_NAME}..."

# Clean up previous build
rm -rf "${BUNDLE_DIR}"

# Create bundle directories
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Generate the application icon bundle from the source artwork.
generate_app_icon

# Compile Swift files
swiftc -parse-as-library \
    -target arm64-apple-macosx13.0 \
    -sdk $(xcrun --show-sdk-path --sdk macosx) \
    Sources/*.swift \
    -o "${MACOS_DIR}/${APP_NAME}"

# Copy Info.plist
cp Sources/Info.plist "${CONTENTS_DIR}/"

# Build AppIcon.icns if make_icon.sh exists
if [ -f "./make_icon.sh" ]; then
    bash ./make_icon.sh
fi

# Copy AppIcon.icns if it exists
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "${RESOURCES_DIR}/"
fi

# Sign the app (Ad-hoc)
codesign --force --deep --sign - "${BUNDLE_DIR}"

echo "Build successful! App created at ${BUNDLE_DIR}"
