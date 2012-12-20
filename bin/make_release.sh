#!/bin/bash
VERSION=`grep "set(FLANN_VERSION" CMakeLists.txt  | sed 's/[^0-9]*\([0-9]*\.[0-9]*\.[0-9]*\)[^0-9]*/\1/'`

echo "Creating flann-$VERSION-src.zip"

git archive --prefix=flann-$VERSION-src/ -o flann-$VERSION-src.zip $VERSION-src
