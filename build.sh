#!/bin/bash

# Copyright (c) 2018, Arm Limited and affiliates.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SELF="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done

THIS_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

pushd $THIS_DIR

if [ \( -n "$DEBUG" \) -o \( -n "$DEBUG2" \) ]; then
  echo "DEBUG ON"
  GOTAGS="-tags debug"
	make native.a-debug
else
	make native.a
fi

for f in $(find  src -name '*\.go'); do
	FILENAME=`basename $f`
	DIR1=`dirname $f`
	DIR1=${DIR1#*/}
	if [ "$DIR1" != "src" ]; then
		mkdir -p $DIR1
		cp src/$DIR1/$FILENAME $DIR1/$FILENAME
	else
		cp src/$FILENAME $FILENAME
	fi
done

for f in $(find  src -name '*\.[ch]'); do
	FILENAME=`basename $f`
	DIR1=`dirname $f`
	DIR1=${DIR1#*/}
	if [ "$DIR1" != "src" ]; then
		mkdir -p $DIR1
		cp src/$DIR1/$FILENAME $DIR1/$FILENAME
	else
		cp src/$FILENAME $FILENAME
	fi
done

popd

if [ "$1" == "removesrc" ]; then
	if [ -d src ]; then
		mv src .src
	fi
	shift
fi

# let's get the current commit, and make sure Version() has this.
COMMIT=`git rev-parse --short=7 HEAD`
DATE=`date`
sed -i -e "s/COMMIT_NUMBER/${COMMIT}/g" maestroutils/status.go 
sed -i -e "s/BUILD_DATE/${DATE}/g" maestroutils/status.go 

# highlight errors: https://serverfault.com/questions/59262/bash-print-stderr-in-red-color
# color()(set -o pipefail;"$@" 2>&1>&3|sed $'s,.*,\e[31m&\e[m,'>&2)3>&1

if [ "$1" != "preprocess_only" ]; then
	pushd $GOPATH/bin
  echo $PWD
	if [ ! -z "$TIGHT" ]; then
	    go build $GOTAGS -ldflags="-s -w" "$@" github.com/armPelionEdge/maestro/maestro 
	else
	    go build $GOTAGS "$@" github.com/armPelionEdge/maestro/maestro 
	fi
  echo $?
	popd
fi
