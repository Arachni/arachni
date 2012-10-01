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

if [ -z "$ARACHNI_BUILD_BRANCH" ]; then
    ARACHNI_BUILD_BRANCH="experimental"
fi

echo "Getting system version from the '$ARACHNI_BUILD_BRANCH' branch/tag."
version=`wget -q -O - https://raw.github.com/Arachni/arachni/$ARACHNI_BUILD_BRANCH/lib/version`

if [[ $? != 0 ]]; then
    echo "Could not determine the version number of '$ARACHNI_BUILD_BRANCH'."
    exit 1
fi

echo "Building version: $version"

os=`uname -s | awk '{print tolower($0)}'`

if [[ -e "/32bit-chroot" ]]; then
    arch="i386"
else
    arch=`uname -m`
fi

pkg_name="arachni-$version"

installer_name="$pkg_name-$os-$arch-installer.sh"
archive="$pkg_name-$os-$arch.tar.gz"

cat<<EOF

@@@ Building
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

EOF
bash "$root/build.sh" $pkg_name

if [[ "$?" != 0 ]]; then
    echo "============ Building failed."
    exit 1
fi



cat<<EOF

@@@ Packaging
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

EOF
bash "$root/package.sh" $installer_name $pkg_name

if [[ "$?" != 0 ]]; then
    echo "============ Packaging failed."
    exit 1
fi

mv "$installer_name.tar.gz" $archive

echo
cat<<EOF
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


Completed successfully!

Archive is at:   $archive
Installer is at: $installer_name

Cheers,
The Arachni team.

EOF
