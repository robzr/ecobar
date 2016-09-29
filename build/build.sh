#!/bin/bash

DIR=~/github/ecobar
BUILD_DIR=$DIR/build

ICON_SRC=$BUILD_DIR/icon/ecoBar.icns
DMG_SRC=$BUILD_DIR/src/ecoBar.dmg DMG_DEST="$DIR/ecoBar.dmg"
DMG_TMP=/tmp/tmp-ecoBar.dmg
MNT_DIR="/Volumes/ecoBar Installer"
BBD_DIR="$BUILD_DIR/src/BitBarDistro.app"
APP_DIR="$MNT_DIR/ecoBar.app"
INST_DIR="$APP_DIR/Contents/MacOS"

ECOBEE_DIR=~/github/ecobee/lib

echo Converting DMG
hdiutil detach "$MNT_DIR"
#hdiutil convert "$DMG_SRC" -format UDRW -ov -o "$DMG_TMP"
cp "$DMG_SRC" "$DMG_TMP"
hdiutil attach "$DMG_TMP"

#echo Removing old directories...
#rm -rf "$INST_DIR/ecobee" "$INST_DIR/ecoBar.1m.rb" "$INST_DIR/eco_bar"

echo Copying BitBarDistro
rm -rf "$APP_DIR"
rsync -a "$BBD_DIR"/ "$APP_DIR"

echo Copying files in...
rsync -a "$DIR/eco_bar" "$INST_DIR"
cp "$DIR/ecoBar.rb" "$INST_DIR/ecoBar.1m.rb"
rsync -a "$ECOBEE_DIR/" "$INST_DIR/ecobee"

echo Unsigning...
xattr -rc "$APP_DIR"
codesign --deep --force --verbose --sign - "$APP_DIR"
#echo Signing...
#codesign --deep --force --verbose --sign "Mac Developer: rob@zwissler.org (M3AY8937F4)" "$APP_DIR"

echo Applying icon
# make icon it's own icon
sips -i "$ICON_SRC"
# extract to resource file
DeRez -only icns "$ICON_SRC" > /tmp/icon.$$
# append this resource to the file you want to icon-ize.
Rez -append /tmp/icon.$$ -o "$APP_DIR"/$'Icon\r'
# Use the resource to set the icon.
#SetFile -a C "$APP_DIR"/Icon?
SetFile -a C "$APP_DIR"/
SetFile -a V "$APP_DIR"/$'Icon\r'
rm /tmp/icon.$$

echo Verifying sign...
codesign --verify --verbose "$APP_DIR"

sleep 3
hdiutil detach "$MNT_DIR"
#diskutil unmount "$MNT_DIR"
sleep 2
echo Converting...
echo hdiutil convert "$DMG_TMP" -quiet -format UDZO -imagekey zlib-level=9 -ov -o "$DMG_DEST"
hdiutil convert "$DMG_TMP" -format UDZO -imagekey zlib-level=9 -ov -o "$DMG_DEST"

#hdiutil create $DIR/ecoBar.dmg -volname "ecoBar Installer" -srcfolder $DIR/build/image

#Use hdiutil to attach the image
#Use cp etc to copy the application into the mounted image
#hdiutil detach
#compress the image: hdiutil convert "in.dmg" -quiet -format UDZO -imagekey zlib-level=9 -o "MyApp-0.3.dmg"
