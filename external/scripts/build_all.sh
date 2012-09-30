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

path_to_readlink_function=`dirname $0`"/lib/readlink_f.sh"
if [[ ! -e "$path_to_readlink_function" ]]; then
    echo "Could not find $path_to_readlink_function"
    exit
fi

source $path_to_readlink_function

root="$(dirname "$(readlink_f "${0}")")"

export xterm="xterm -geometry 80X10 -hold"
xterm -T "Building 32bit packages" -e "touch 32bit_build.lock && bash $root/cross_build_and_package.sh; rm 32bit_build.lock" &
xterm -T "Building 64bit packages" -e "touch 64bit_build.lock && bash $root/build_and_package.sh && rm 64bit_build.lock" &
