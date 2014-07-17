#! /bin/bash
# Install vpython and vpip on path (so we need root, unless we want to place it in ~/bin)

REPO_URL="https://github.com/tbug/vpython"

# Installer directory (we should not be behind a link, so that simplifies it a bit)
DIR="$( cd "$( dirname "${0}" )" && pwd )"

LOCAL_INSTALL="$HOME/bin"
GLOBAL_INSTALL="/usr/bin"

VPIP_NAME="vpip"
VPYTHON_NAME="vpython"

# Check if vpython and vpip is next to the installer (someone cloned the repo and run it)
VPIP_PATH="$DIR/$VPIP_NAME.sh"
VPYTHON_PATH="$DIR/$VPYTHON_NAME.sh"

if [ "${1}" == "-u" ]; then
    ALLOW_UPDATE=true
else
    ALLOW_UPDATE=false
fi


if [ ! -f $VPYTHON_PATH ] || [ ! -f $VPIP_PATH ]; then
    # Install by cloning repo and running the install again
    echo "Clone the entire repository at ${REPO_URL} and run the installer from the source" >&2
    exit 2
fi


# Symlink to path
if [ -d "$LOCAL_INSTALL" ]; then
    # The local bin folder exists, use it
    TARGET_DIR="$LOCAL_INSTALL"
else
    # Else target global path
    TARGET_DIR="$GLOBAL_INSTALL"
fi

if [ "$TARGET_DIR" == "$GLOBAL_INSTALL" ]; then
    # If we target global, we need root
    if [ "$(id -u)" != "0" ]; then
       echo "You must run the installer as root for it to symlink vpython to /usr/bin" >&2
       echo "Alternatively create a ~/bin folder, add it to your path, and run the installer again" >&2
       exit 1
    fi
fi

if [ -f "$TARGET_DIR/$VPYTHON_NAME" ]; then
    if $ALLOW_UPDATE; then
        rm "$TARGET_DIR/$VPYTHON_NAME"
    else
        echo -e "vpython file already exists at $TARGET_DIR/$VPYTHON_NAME\nRun installer with -u flag to allow update:\n    ${0} -u" >&2
        exit 1
    fi
fi
ln -s "$VPYTHON_PATH" "$TARGET_DIR/$VPYTHON_NAME"


if [ -f "$TARGET_DIR/$VPIP_NAME" ]; then
    if $ALLOW_UPDATE; then
        rm "$TARGET_DIR/$VPIP_NAME"
    else
        echo -e "vpip file already exists at $TARGET_DIR/$VPIP_NAME\nRun installer with -u flag to allow update:\n    ${0} -u" >&2
        exit 1
    fi
fi
ln -s "$VPIP_PATH" "$TARGET_DIR/$VPIP_NAME"
