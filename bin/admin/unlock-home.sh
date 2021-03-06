#! /usr/bin/env bash
# vim: set filetype=sh ts=4 sw=4 sts=4 et:
CONFIGFILE=/etc/bastion/luks-config.sh
# shellcheck source=etc/bastion/luks-config.sh.dist
. "$CONFIGFILE"

do_mount()
{
    mount "$MOUNTPOINT"; ret=$?
    if [ $ret -eq 0 ] ; then
        echo "Success!"
    else
        echo "Failure... is $MOUNTPOINT correctly specified in /etc/fstab?"
    fi
    exit $ret
}

if [ -z "$DEV_ENCRYPTED" ] || [ -z "$UNLOCKED_NAME" ] || [ -z "$MOUNTPOINT" ] || [ ! -d "$MOUNTPOINT" ] || [ ! -b "$DEV_ENCRYPTED" ] ; then
    echo "Not configured or badly configured (check $CONFIGFILE), nothing to do."
    exit 0
fi

if [ -e "$MOUNTPOINT/allowkeeper" ] ; then
    echo "Already unlocked and mounted"
    exit 0
fi

DEV_UNLOCKED="/dev/disk/by-id/dm-name-$UNLOCKED_NAME"
if [ -e "$DEV_UNLOCKED" ] ; then
    echo "Already unlocked ($DEV_UNLOCKED), mounting..."
    do_mount
fi

echo "Mouting $DEV_ENCRYPTED as $UNLOCKED_NAME"
cryptsetup luksOpen "$DEV_ENCRYPTED" "$UNLOCKED_NAME"
sleep 1
if [ -e "$DEV_UNLOCKED" ] ; then
    echo "Mounting..."
    do_mount
else
    echo "Partition still encrypted, bad password?"
    exit 1
fi

