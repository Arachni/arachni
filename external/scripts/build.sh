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
installer_name="$pkg_name-`uname -m`-linux-installer.sh"

cat<<EOF
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Building
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

EOF

cat<<EOF
@@ Creating installation
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

EOF
bash "$root/install.sh" $pkg_name

if [[ "$?" != 0 ]]; then
    echo "============ Installation failed."
    exit 1
fi



cat<<EOF
@@ Creating package installer
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

EOF
bash "$root/package.sh" $installer_name $pkg_name

if [[ "$?" != 0 ]]; then
    echo "============ Packaging failed."
    exit 1
fi

echo
cat<<EOF
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


Build completed succesfully!

Installer is at: $installer_name

Cheers,
The Arachni team.

EOF
