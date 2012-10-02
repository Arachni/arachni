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
nightlies="$HOME/builds/nightlies"

package_patterns="arachni*.gz"
dest="segfault@downloads.arachni-scanner.com:www/arachni/downloads/nightlies/"

rm -f $package_patterns

output_log_32bit="$root/32bit.log"
output_log_64bit="$root/64bit.log"

rm -f $output_log_32bit
rm -f $output_log_64bit

if [ -n "${OSX_SSH_CMD+x}" ]; then
    output_log_osx="$root/osx.log"
    rm -f $output_log_osx
fi

mkdir -p $nightlies
cd $nightlies

if ls *.lock > /dev/null 2>&1; then
    echo "Found a lock file, another build process is in progress or the dir is dirty.";
    exit 1
fi

if ls *.pid > /dev/null 2>&1; then
    echo "Found a pid file, another build process is in progress or the dir is dirty.";
    exit 1
fi

rm -f arachn*.gz arachn*installer.sh
rm -f *.log

echo "Building packages, this could take a while; to monitor the progress of the:"
echo "  * 32bit build: tail -f $output_log_32bit"
echo "  * 64bit build: tail -f $output_log_64bit"


if [ -n "${OSX_SSH_CMD+x}" ]; then
    echo "  * OSX build: tail -f $output_log_osx"
fi

echo
echo 'You better go grab some coffee now...'

bash -c "touch 32bit_build.lock && \
    bash $root/cross_build_and_package.sh 2>> $output_log_32bit 1>> $output_log_32bit ;\
    rm 32bit_build.lock" &

echo $! > 32bit.pid

bash -c "touch 64bit_build.lock && \
    bash $root/build_and_package.sh 2>> $output_log_64bit 1>> $output_log_64bit &&\
    rm 64bit_build.lock" &

echo $! > 64bit.pid

if [ -n "${OSX_SSH_CMD+x}" ]; then
    bash -c "touch osx_build.lock && \
        eval \"$OSX_SSH_CMD\" 2>> $output_log_osx 1>> $output_log_osx &&\
        rm osx_build.lock" &

    echo $! > 64bit.pid
fi

# wait for the locks to be created
while [ ! -e "32bit_build.lock" ]; do sleep 0.1; done
while [ ! -e "64bit_build.lock" ]; do sleep 0.1; done

if [ -n "${OSX_SSH_CMD+x}" ]; then
    while [ ! -e "osx_build.lock" ]; do sleep 0.1; done
fi


# and then wait for the locks to be removed
while [ -e "32bit_build.lock" ]; do sleep 0.1; done
echo '  * 32bit package ready'

while [ -e "64bit_build.lock" ]; do sleep 0.1; done
echo '  * 64bit package ready'

if [ -n "${OSX_SSH_CMD+x}" ]; then
    while [ -e "osx_build.lock" ]; do sleep 0.1; done
    echo '  * OSX package ready'
fi


echo
echo -n 'Removing PID files'
rm *.pid
echo ' - done.'
echo

echo 'Pushing to server, this could take a while also...'
rsync --human-readable --progress --executability --compress --stats \
    $package_patterns $dest

echo
echo 'All done.'
