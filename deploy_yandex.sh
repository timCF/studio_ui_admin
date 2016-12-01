#!/bin/bash
UPLOAD_URL=$(curl -H "Authorization: OAuth $YANDEX_TOKEN" "https://cloud-api.yandex.net/v1/disk/resources/upload?fields=href&overwrite=true&path=%2Fdesktop_builds%2Fstudio_ui_admin.zip" | sed -e 's/^.*"href"[ ]*:[ ]*"//' -e 's/".*//') &&
curl $UPLOAD_URL --upload-file $1
