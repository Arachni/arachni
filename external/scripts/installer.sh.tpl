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

#
# Based on: http://lembra.wordpress.com/2011/09/04/how-to-generate-a-bash-script-with-an-embeeded-tar-gz-self-extract/
#

cat<<EOF

            Arachni installer (experimental)
            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 It extracts a pre-configured, self-contained installation.

     by Tasos Laskos <tasos.laskos@gmail.com>
-------------------------------------------------------------------------

EOF

# will be substituted by package.sh
pkg_name="##PKG_NAME##"

# default installation dir
instdir="/opt"

# where to put symlinks to the executables
binpath="/usr/local/bin"

if [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    cat <<EOF
Usage: $0 [installation directory]

Installation directory defaults to '$instdir'.

EOF
    exit
fi

echo
echo "# Checking for installation dependencies"
echo '----------------------------------------'
deps="
    tar
    awk
    tail
    basename
    dirname
"
for dep in $deps; do
    echo -n "  * $dep"
    if [[ ! `which "$dep"` ]]; then
        echo " -- FAIL"
        fail=true
    else
        echo " -- OK"
    fi
done

echo
if [[ $fail ]]; then
    echo "Please install the missing dependencies and try again."
    exit 1
fi

if [[ ! -z "$1" ]]; then
    instdir=`readlink_f $1`
fi

if [[ ! -s $instdir ]]; then
    echo "Directory '$instdir' does not exist."
    exit 1
fi

touch "$instdir/perm-check" &> /dev/null
if [[ "$?" != 0 ]]; then
    echo -n "Could not write to '$instdir', make sure you have enough "
    echo "permissions or specify a different directory."
    exit 1
fi
rm "$instdir/perm-check"

echo
echo "# Installing"
echo '----------------------------------------'

echo "  * Extracting files under $instdir"

# searches for the line number where finish the script and start the tar.gz
SKIP=`awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' $0`

#remember our file name
THIS=`pwd`/$0

# take the tarfile and pipe it into tar
tail -n +$SKIP $THIS | tar -xzf - -C $instdir

touch "$binpath/perm-check" &> /dev/null
if [[ "$?" != 0 ]]; then

    pkg_bin="$instdir/$pkg_name/bin"
    rc="$HOME/.bashrc"

    echo "  * Can't write to '$binpath', installing for current user only."
    echo "    o Adding '$pkg_bin' to PATH using '$rc'."

    egrep "$pkg_bin" $rc &> /dev/null
    if [ $? -ne 0 ] ; then
        echo "export PATH=$pkg_bin:\$PATH" >> $rc
    fi

    echo
    echo " ==== In order for the changes to take effect please execute:"
    echo "    source $rc"
else
    rm "$binpath/perm-check"

    echo "  * Creating symlinks for executables"
    for bin in $instdir/$pkg_name/bin/*; do
        bin_name=`basename $bin`
        echo "    o $binpath/$bin_name => $bin"

        ln -fs $bin "$binpath/$bin_name"
        chmod +x "$binpath/$bin_name"
    done
fi

# Any script here will happen after the tar file extract.
echo
cat<<EOF
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Installation completed successfully!

Useful resources:
    * Homepage     - http://arachni-scanner.com/
    * Blog         - http://arachni-scanner.com/blog
    * Wiki         - http://arachni-scanner.com/wiki
    * GitHub page  - http://github.com/Arachni/arachni
    * Google Group - http://groups.google.com/group/arachni
    * Twitter      - http://twitter.com/ArachniScanner

Have fun ;)

Cheers,
The Arachni team.

EOF

exit 0

# NOTE: Don't place any newline characters after the last line below.
__TARFILE_FOLLOWS__
