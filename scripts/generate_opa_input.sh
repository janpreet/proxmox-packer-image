#!/bin/bash

IMAGE_PATH=$1
MOUNT_POINT=$(mktemp -d)

guestmount -a $IMAGE_PATH -i $MOUNT_POINT

PACKAGES=$(chroot $MOUNT_POINT dpkg -l | awk '/^ii/ {print $2}' | jq -R -s -c 'split("\n")[:-1]')

SHADOW_PERMS=$(stat -c '%a' $MOUNT_POINT/etc/shadow)
PASSWD_PERMS=$(stat -c '%a' $MOUNT_POINT/etc/passwd)
SIGNATURE_PERMS=$(stat -c '%a' $MOUNT_POINT/etc/janpreet_signature)

SENSITIVE_FILES=$(grep -r -i -l 'PRIVATE KEY\|API_KEY\|PASSWORD' $MOUNT_POINT | jq -R -s -c 'split("\n")[:-1]')

WATERMARK=$(cat $MOUNT_POINT/etc/janpreet_signature)

guestunmount $MOUNT_POINT

cat << EOF
{
  "packages": $PACKAGES,
  "file_permissions": {
    "/etc/shadow": $SHADOW_PERMS,
    "/etc/passwd": $PASSWD_PERMS,
    "/etc/janpreet_signature": $SIGNATURE_PERMS
  },
  "files": $SENSITIVE_FILES,
  "watermark": "$WATERMARK"
}
EOF