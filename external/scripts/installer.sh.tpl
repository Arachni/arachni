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

dir="/opt/##DIR##"

if [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    cat <<EOF
Usage: $0 [installation directory]

Installation directory defaults to '$dir'.

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
    dir="$1"
fi

basedir=`dirname $dir`
binpath="/usr/local/bin"

touch "$binpath/perm-check" &> /dev/null
if [[ "$?" != 0 ]]; then
    echo "Can't write to '$binpath', make sure you have enough permissions and try again."
    echo "(HINT: Run the script as 'root'.)"
    exit 1
fi
rm "$binpath/perm-check"

if [[ ! -s $basedir ]]; then
    echo "'$basedir' does not exist."
    exit 1
fi

touch "$basedir/perm-check" &> /dev/null
if [[ "$?" != 0 ]]; then
    echo "Could not write to '$basedir', make sure you have enough permissions and try again."
    exit 1
fi
rm "$basedir/perm-check"

echo
echo "# Installing"
echo '----------------------------------------'

echo "  * Extracting files in $dir"

# searches for the line number where finish the script and start the tar.gz
SKIP=`awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' $0`

#remember our file name
THIS=`pwd`/$0

# take the tarfile and pipe it into tar
tail -n +$SKIP $THIS | tar -xz -C $basedir

echo "  * Creating symlinks for executables"
for bin in $dir/bin/*; do
    bin_name=`basename $bin`
    echo "    o $binpath/$bin_name => $bin"

    ln -fs $bin "$binpath/$bin_name"
    chmod +x "$binpath/$bin_name"
done


# Any script here will happen after the tar file extract.
echo
cat<<EOF
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Installation completed succesfully!

Useful resources:
    * Homepage     - http://arachni-scanner.com/
    * Blog         - http://arachni-scanner.com/blog
    * Wiki         - http://arachni-scanner.com/wiki
    * GitHub page  - http://github.com/zapotek/arachni
    * Google Group - http://groups.google.com/group/arachni
    * Twitter      - http://twitter.com/ArachniScanner

Have fun ;)

Cheers,
The Arachni team.

EOF

exit 0

# NOTE: Don't place any newline characters after the last line below.
__TARFILE_FOLLOWS__
