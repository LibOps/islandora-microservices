#!/usr/bin/env bash

set -eou pipefail

terraform output -json > output.json
cat output.json
KEYS=$(jq -r '.urls.value | keys[]' output.json)
echo "$KEYS"
for KEY in $KEYS; do
  URL=$(jq -r ".urls.value[\"$KEY\"]" output.json)
  echo "Testing $KEY at $URL"

  if [ "$KEY" == "crayfits" ]; then
    curl -s -o fits.xml \
        --header "Accept: application/xml" \
        --header "Apix-Ldp-Resource: https://www.libops.io/themes/custom/libops_www/assets/img/200x200/islandora.png" \
        "$URL"
    # check the md5 of that file exists in the FITS XML
    grep d6c508e600dcd72d86b599b3afa06ec2 fits.xml | grep md5checksum
    rm fits.xml
  elif [ "$KEY" == "homarus" ]; then
    curl -s -o image.jpg \
        --header "X-Islandora-Args: -ss 00:00:45.000 -frames 1 -vf scale=720:-2" \
        --header "Accept: image/jpeg" \
        --header "Apix-Ldp-Resource: http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4" \
        "$URL"
    md5 image.jpg | grep fe7dd57460dbaf50faa38affde54b694
    rm image.jpg
  elif [ "$KEY" == "houdini" ]; then
    curl -s -o image.png \
        --header "Accept: image/png" \
        --header "Apix-Ldp-Resource: https://www.libops.io/themes/custom/libops_www/assets/img/200x200/islandora.png" \
        "$URL"
    file image.png | grep PNG
    rm image.png
  elif [ "$KEY" == "hypercube" ]; then
    curl -s -o ocr.txt \
        --header "Accept: text/plain" \
        --header "Apix-Ldp-Resource: https://www.libops.io/sites/default/files/2024-05/Screen%20Shot%20on%202024-05-21%20at%2002-32-42.png" \
        "$URL"
    grep healthcheck ocr.txt
    rm ocr.txt
  else
    echo "Unknown service"
    exit 1
  fi
done
rm output.json
