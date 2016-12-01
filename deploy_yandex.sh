#!/bin/bash
UPLOAD_URL=$(curl -H "Authorization: OAuth $YANDEX_TOKEN" "https://cloud-api.yandex.net/v1/disk/resources/upload?fields=href&overwrite=true&path=%2Felixir_releases%2Fstudio_ui_admin" | sed -e 's/^.*"href"[ ]*:[ ]*"//' -e 's/".*//') &&
curl $UPLOAD_URL --upload-file $1
