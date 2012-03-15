#!/usr/bin/env bash
#
# Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

readlink_f(){
    # from: http://stackoverflow.com/a/1116890
    # Mac OS specific because readlink -f doesn't work
    if [[ "Darwin" == "$(uname)" ]]; then
        TARGET_FILE=$1

        cd `dirname $TARGET_FILE`
        TARGET_FILE=`basename $TARGET_FILE`

        # Iterate down a (possible) chain of symlinks
        while [ -L "$TARGET_FILE" ]; do
            TARGET_FILE=`readlink $TARGET_FILE`
            cd `dirname $TARGET_FILE`
            TARGET_FILE=`basename $TARGET_FILE`
        done

        # Compute the canonicalized name by finding the physical path
        # for the directory we're in and appending the target file.
        PHYS_DIR=`pwd -P`
        echo $PHYS_DIR/$TARGET_FILE
    else
        readlink -f $1
    fi
}
