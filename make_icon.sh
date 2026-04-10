#!/bin/bash
set -e

IMG="/Users/mohammedhassnen/.gemini/antigravity/brain/e6e2af0e-eaf6-457c-a8e2-ffb48d5f72d5/lid_controller_app_icon_1773560194553.png"

echo "Generating AppIcon.icns..."
rm -rf AppIcon.iconset AppIcon.icns
mkdir AppIcon.iconset

sips -z 16 16     $IMG --out AppIcon.iconset/icon_16x16.png > /dev/null
sips -z 32 32     $IMG --out AppIcon.iconset/icon_16x16@2x.png > /dev/null
sips -z 32 32     $IMG --out AppIcon.iconset/icon_32x32.png > /dev/null
sips -z 64 64     $IMG --out AppIcon.iconset/icon_32x32@2x.png > /dev/null
sips -z 128 128   $IMG --out AppIcon.iconset/icon_128x128.png > /dev/null
sips -z 256 256   $IMG --out AppIcon.iconset/icon_128x128@2x.png > /dev/null
sips -z 256 256   $IMG --out AppIcon.iconset/icon_256x256.png > /dev/null
sips -z 512 512   $IMG --out AppIcon.iconset/icon_256x256@2x.png > /dev/null
sips -z 512 512   $IMG --out AppIcon.iconset/icon_512x512.png > /dev/null
cp $IMG AppIcon.iconset/icon_512x512@2x.png

iconutil -c icns AppIcon.iconset
rm -rf AppIcon.iconset
echo "AppIcon.icns generated."
