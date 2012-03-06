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

root="$(dirname "$(readlink -f "${0}")")"
version=`cat $root/../../lib/version`

pkg_name="arachni-$version"

if [[ -e "/32bit-chroot" ]]; then
    arch="x86_32"
else
    arch=`uname -m`
fi

installer_name="$pkg_name-$arch-linux-installer.sh"

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

archive="$pkg_name-$arch-linux.tar.gz"
mv "$installer_name.tar.gz" $archive

echo
cat<<EOF
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


Completed succesfully!

Archive is at:   $archive
Installer is at: $installer_name

Cheers,
The Arachni team.

EOF
