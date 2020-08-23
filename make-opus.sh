#!/bin/bash
set -e

DIR_PATH="$(realpath "${0}" | xargs dirname)"
OLD_PATH="$PWD"

echo "Bulding Opus... be patient"

cd "${DIR_PATH}"
curl -L 'https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz' | tar xz

cd 'opus-1.3.1'

./configure --disable-shared --enable-shared=no \
	--disable-doc --disable-extra-programs \
	--prefix="${DIR_PATH}" > /dev/null
make >/dev/null
make install >/dev/null

cd "${OLD_PATH}"
echo "Opus build complete"
