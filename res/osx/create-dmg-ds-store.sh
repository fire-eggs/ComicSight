#!/bin/sh

VOLNAME=$1
BACKGROUND=$2

if [ $# != 2 ] || [ "$1" = "" ] || [ "$2" = "" ]; then
  echo "Incorrect number of arguments" 1>&2
  exit 1
fi

if [ -d "/Volumes/$VOLNAME" ]; then
  hdiutil detach "/Volumes/$VOLNAME"
fi

if [ -d "/Volumes/$VOLNAME" ]; then
  echo "'/Volumes/$VOLNAME' could not be unmounted" 1>&2
  exit 1
fi

rm DS_Store.dmg
hdiutil create -size 1m -fs HFS+ -volname "$VOLNAME" DS_Store.dmg
hdiutil attach DS_Store.dmg

cp "$BACKGROUND" "/Volumes/$VOLNAME/background.png"
mkdir "/Volumes/$VOLNAME/ComicSight.app"
touch "/Volumes/$VOLNAME/Applications"

osascript << END
  tell application "Finder"
    open contents of ( POSIX file "/Volumes/$VOLNAME" as alias )
    tell Finder window 1
      set toolbar visible to false
      set sidebar width to 0
      set statusbar visible to false
      set current view to icon view
      set bounds to {200, 120, 728, 472}

      set position of item "ComicSight.app" to {112, 202}
      set position of item "Applications" to {416, 202}

      tell its icon view options
        set arrangement to not arranged
        set icon size to 128
        set background picture to ( POSIX file "/Volumes/$VOLNAME/background.png" as alias )
      end tell
      close
    end tell
  end tell
END

hdiutil detach "/Volumes/$VOLNAME"
hdiutil attach DS_Store.dmg

cp "/Volumes/$VOLNAME/.DS_Store" ./DS_Store
hdiutil detach "/Volumes/$VOLNAME"
