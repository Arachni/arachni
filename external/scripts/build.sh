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
# Experimental Arachni install script, it's supposed to take care of everything
# including system library dependencies, Ruby, gem dependencies and Arachni itself.
#
# Credits:
#     Tasos Laskos <tasos.laskos@gmail.com> -- Original Linux version
#     Edwin van Andel <evanandel@yafsec.com> -- Patches for *BSD and testing
#     Dan Woodruff <daniel.woodruff@gmail.com> -- Patches for OSX and testing
#

path_to_readlink_function=`dirname $0`"/lib/readlink_f.sh"
if [[ ! -e "$path_to_readlink_function" ]]; then
    echo "Could not find $path_to_readlink_function"
    exit
fi

source $path_to_readlink_function

cat<<EOF

               Arachni builder (experimental)
            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 It will create an environment, download and install all dependencies in it,
 configure it and install Arachni itself in it.

     by Tasos Laskos <tasos.laskos@gmail.com>
-------------------------------------------------------------------------

EOF

if [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    cat <<EOF
Usage: $0 [build directory]

Build directory defaults to 'arachni'.

If at any point you decide to cancel the process, re-running the script
will continue from the point it left off.

EOF
    exit
fi

echo
echo "# Checking for script dependencies"
echo '----------------------------------------'
deps="
    wget
    gcc
    g++
    awk
    sed
    grep
    make
    expr
    perl
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

if [[ $fail ]]; then
    echo "Please install the missing dependencies and try again."
    exit 1
fi

echo

if [ -z "$ARACHNI_BUILD_BRANCH" ]; then
    ARACHNI_BUILD_BRANCH="experimental"
    echo "---- No branch/tag specified, defaulting to: $ARACHNI_BUILD_BRANCH"
fi

echo "---- Building branch/tag: $ARACHNI_BUILD_BRANCH"

arachni_tarball_url="https://github.com/Arachni/arachni/tarball/$ARACHNI_BUILD_BRANCH"

#
# All system library dependencies in proper order
#
libs=(
    http://zlib.net/zlib-1.2.7.tar.gz
    http://www.openssl.org/source/openssl-1.0.1c.tar.gz
    http://www.sqlite.org/sqlite-autoconf-3071300.tar.gz
    ftp://xmlsoft.org/libxml2/libxml2-2.8.0.tar.gz
    ftp://xmlsoft.org/libxslt/libxslt-1.1.26.tar.gz
    http://curl.haxx.se/download/curl-7.26.0.tar.gz
    https://rvm.io/src/yaml-0.1.4.tar.gz
    http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p194.tar.gz
)

#
# The script will look for the existent of files whose name begins with the following
# strings to see if a lib has already been installed.
#
# They should correspond with the entries in the 'libs' array.
#
libs_so=(
    libz
    libssl
    libsqlite3
    libxml2
    libxslt
    libcurl
    libyaml-0
    ruby
)

if [[ ! -z "$1" ]]; then
    # root path
    root="$1"
else
    # root path
    root="arachni"
fi

clean_build="arachni-clean"
if [[ -d $clean_build ]]; then

    echo
    echo "==== Found backed up clean build ($clean_build), using it as base."

    rm -rf $root
    cp -R $clean_build $root
else
    mkdir -p $root
fi

update_clean_dir=false

# *BSD's readlink doesn't like non-existent dirs
root=`readlink_f $root`

scriptdir=`readlink_f $0`

# holds tarball archives
archives_path="$root/archives"

# holds exracted archives
src_path="$root/src"

# holds STDERR and STDOUT
logs_path="$root/logs"

# --prefix value for 'configure' scripts
configure_prefix="$root/usr"
usr_path=$configure_prefix

# PATH for our Ruby environment
bin_path="$root_path/bin:$usr_path/bin"

# Gem storage directories
gem_home="$root/gems"
gem_path=$gem_home

#
# Special config for packages that need something extra.
# These are called dynamically using the obvious naming convention.
#
# For some reason assoc arrays don't work...
#
configure_libxslt="./configure --with-libxml-prefix=$configure_prefix"

configure_libxml="./configure --with-liiconv-prefix=$configure_prefix"

configure_ruby="./configure --with-opt-dir=$configure_prefix \
--with-libyaml-dir=$configure_prefix \
--with-zlib-dir=$configure_prefix \
--with-openssl-dir=$configure_prefix \
--disable-install-doc --enable-shared"

common_configure_openssl="-I$usr_path/include -L$usr_path/lib \
zlib no-asm no-krb5 shared"

# openssl uses uname to determine os/arch which will return the truth
# even when running in chroot, which is annoying when trying to cross-compile
if [[ -e "/32bit-chroot" ]]; then
    configure_openssl="./Configure $common_configure_openssl \
--prefix=$configure_prefix linux-generic32"

elif [[ "Darwin" == "$(uname)" ]]; then

    hw_machine=$(sysctl hw.machine | awk -F: '{print $2}' | sed 's/^ //')
    hw_cpu64bit=$(sysctl hw.cpu64bit_capable | awk '{print $2}')

    if [[ "Power Macintosh" == "$hw_machine" ]] ; then
        if [[ $hw_cpu64bit == 1 ]]; then
            openssl_os="darwin64-ppc-cc"
        else
            openssl_os="darwin-ppc-cc"
        fi
    else
        if [[ $hw_cpu64bit == 1 ]]; then
            openssl_os="darwin64-x86_64-cc"
        else
            openssl_os="darwin-i386-cc"
        fi
    fi
    configure_openssl="./Configure $openssl_os $common_configure_openssl"
else
    configure_openssl="./config $common_configure_openssl"
fi

configure_curl="./configure \
--with-ssl=$usr_path \
--with-zlib=$usr_path \
--enable-optimize --enable-nonblocking \
--enable-threaded-resolver --enable-crypto-auth --enable-cookies"

orig_path=$PATH

#
# Creates the directory structure for the env
#
setup_dirs( ) {
    cd $root

    dirs="
        logs
        archives
        bin
        gems
        src
        usr/bin
        usr/include
        usr/info
        usr/lib
        usr/man
    "
    for dir in $dirs
    do
        echo -n "  * $root/$dir"
        if [[ ! -s $dir ]]; then
            echo
            mkdir -p $dir
        else
            echo " -- already exists."
        fi
    done

    cd - > /dev/null
}

#
# Checks the last return value and exits with an error msg on failure
#
handle_failure(){
    rc=$?
    if [[ $rc != 0 ]] ; then
        echo "Build failed, check $logs_path/$1 for details."
        echo "When you resolve the issue you can run the script again to continue where the process left off."
        exit $rc
    fi
}

download() {

    echo -n "  * Downloading $1"
    echo -n " -  0% ETA:      -s"
    wget -c --progress=dot --no-check-certificate $1 $2 2>&1 | \
        while read line; do
            echo $line | grep "%" | sed -e "s/\.//g" | \
            awk '{printf("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%4s ETA: %6s", $2, $4)}'
        done

    echo -e "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b                           "
}

#
# Downloads an archive (by url) and places it under $archives_path
#
download_archive() {
    cd $archives_path

    download $1
    handle_failure $2

    cd - > /dev/null
}

#
# Extracts an archive (by name) under $src_path
#
extract_archive() {
    echo "  * Extracting"
    tar xvf $archives_path/$1-*.tar.gz -C $src_path 2>> $logs_path/$1 1>> $logs_path/$1
    handle_failure $1
}

#
# Installs a package from src by name
#
install_from_src() {
    cd $src_path/$1-*

    echo "  * Cleaning"
    make clean 2>> $logs_path/$1 1>> $logs_path/$1

    eval special_config=\$$"configure_$1"
    if [[ $special_config ]]; then
        configure=$special_config
    else
        configure="./configure"
    fi

    configure="${configure} --prefix=$configure_prefix"

    echo "  * Configuring ($configure)"
    echo "Configuring with: $configure" 2>> $logs_path/$1 1>> $logs_path/$1

    $configure 2>> $logs_path/$1 1>> $logs_path/$1
    handle_failure $1

    echo "  * Compiling"
    make 2>> $logs_path/$1 1>> $logs_path/$1
    handle_failure $1

    echo "  * Installing"
    make install 2>> $logs_path/$1 1>> $logs_path/$1
    handle_failure $1

    cd - > /dev/null
}

get_name(){
    basename $1 | awk -F- '{print $1}'
}

#
# Downloads and install a package by URL
#
download_and_install() {
    name=`get_name $1`

    download_archive $1 $name
    extract_archive $name
    install_from_src $name
    echo
}

#
# Downloads and installs all $libs
#
install_libs() {
    libtotal=${#libs[@]}

    for (( i=0; i<$libtotal; i++ )); do
        so=${libs_so[$i]}
        lib=${libs[$i]}
        idx=`expr $i + 1`

        echo "## ($idx/$libtotal) `get_name $lib`"

        so_files="$usr_path/lib/$so"*
        ls  $so_files &> /dev/null
        if [[ $? == 0 ]] ; then
            echo "  * Already installed, found:"
            for so_file in `ls $so_files`; do
                echo "    o $so_file"
            done
            echo
        else
            update_clean_dir=true
            download_and_install $lib
        fi
    done
}

#
# Returns Bash environmental variable configuration as a string
#
# This should be used by our Ruby env.
#
get_ruby_environment() {

    cd "$env_root/usr/lib/ruby/1.9.1/"
    arch_dir=$(echo x86_64*)
    if [[ -d "$arch_dir" ]]; then
        platform_lib=":\$MY_RUBY_HOME/1.9.1/$arch_dir:\$MY_RUBY_HOME/site_ruby/1.9.1/$arch_dir"
    fi

    arch_dir=$(echo i386*)
    if [[ -d "$arch_dir" ]]; then
        platform_lib=":\$MY_RUBY_HOME/1.9.1/$arch_dir:\$MY_RUBY_HOME/site_ruby/1.9.1/$arch_dir"
    fi

    cat<<EOF
echo "\$LD_LIBRARY_PATH-\$DYLD_LIBRARY_PATH" | egrep \$env_root > /dev/null
if [[ \$? -ne 0 ]] ; then
    export PATH; PATH="\$env_root/usr/bin:\$PATH"
    export LD_LIBRARY_PATH; LD_LIBRARY_PATH="\$env_root/usr/lib:\$LD_LIBRARY_PATH"
    export DYLD_LIBRARY_PATH; DYLD_LIBRARY_PATH="\$env_root/usr/lib:\$DYLD_LIBRARY_PATH"
fi

export RUBY_VERSION; RUBY_VERSION='ruby-1.9.3-p194'
export GEM_HOME; GEM_HOME="\$env_root/gems"
export GEM_PATH; GEM_PATH="\$env_root/gems"
export MY_RUBY_HOME; MY_RUBY_HOME="\$env_root/usr/lib/ruby"
export RUBYLIB; RUBYLIB=\$MY_RUBY_HOME:\$MY_RUBY_HOME/site_ruby/1.9.1:\$MY_RUBY_HOME/1.9.1$platform_lib
export IRBRC; IRBRC="\$env_root/usr/lib/ruby/.irbrc"

EOF
}

#
# Provides a wrapper for executables, it basically sets all relevant
# env variables before calling the executable in question.
#
get_wrapper_environment() {
    cat<<EOF
#!/usr/bin/env bash

source "\$(dirname \$0)/readlink_f.sh"

#
# Slight RVM rip-off
#
env_root="\$(dirname "\$(readlink_f "\${0}")")"/..
if [[ -s "\$env_root/environment" ]]; then
    source "\$env_root/environment"
    exec $1
else
    echo "ERROR: Missing environment file: '\$env_root/environment" >&2
    exit 1
fi

EOF
}

get_wrapper_template() {
    get_wrapper_environment "ruby $1 \"\$@\""
}

get_shell_script() {
    get_wrapper_environment '; export PATH="$env_root/bin:$PATH"; export PS1="arachni-shell\$ "; bash --noprofile --norc'
}

get_test_script() {
    get_wrapper_environment '$GEM_PATH/bin/rspec $(dirname $(dirname `gem which arachni`))'
}

#
# Sets the environment, updates rubygems and installs vital gems
#
prepare_ruby() {
    echo "  * Generating environment configuration ($root/environment)"

    export env_root=$root
    get_ruby_environment > $root/environment
    source $root/environment

    echo "  * Updating Rubygems"
    $usr_path/bin/gem update --system 2>> "$logs_path/ruby_rubygems" 1>> "$logs_path/ruby_rubygems"
    handle_failure "ruby"

    echo "  * Installing sys-proctable"
    download "https://github.com/djberg96/sys-proctable/tarball/master" "-O $archives_path/sys-proctable-pkg.tar.gz" &> /dev/null
    extract_archive "sys-proctable" &> /dev/null

    cd $src_path/*-sys-proctable*

    $usr_path/bin/rake install --trace 2>> "$logs_path/ruby_sys-proctable" 1>> "$logs_path/ruby_sys-proctable"
    handle_failure "ruby_sys-proctable"
    $usr_path/bin/gem build sys-proctable.gemspec 2>> "$logs_path/ruby_sys-proctable" 1>> "$logs_path/ruby_sys-proctable"
    handle_failure "ruby_sys-proctable"
    $usr_path/bin/gem install sys-proctable-*.gem 2>> "$logs_path/ruby_sys-proctable" 1>> "$logs_path/ruby_sys-proctable"
    handle_failure "ruby_sys-proctable"

    echo "  * Installing Bundler"
    $usr_path/bin/gem install bundler --no-ri  --no-rdoc  2>> "$logs_path/ruby_bundler" 1>> "$logs_path/ruby_bundler"
    handle_failure "ruby_bundler"
}

install_arachni() {

    rm "$archives_path/arachni-pkg.tar.gz" &> /dev/null
    download $arachni_tarball_url "-O $archives_path/arachni-pkg.tar.gz"
    handle_failure "arachni"

    extract_archive "arachni"

    cd $src_path/Arachni-arachni*

    echo "  * Preparing the bundle"
    $gem_path/bin/bundle install 2>> "$logs_path/arachni" 1>> "$logs_path/arachni"
    handle_failure "arachni"

#    echo "  * Testing -- This will take some time ('tail -f $logs_path/arachni' for progress)."
#    $gem_path/bin/bundle exec $usr_path/bin/rake spec:core 2>> "$logs_path/arachni" 1>> "$logs_path/arachni"
#    handle_failure "arachni"

    echo "  * Installing"
    $usr_path/bin/rake install --trace 2>> "$logs_path/arachni" 1>> "$logs_path/arachni"
    handle_failure "arachni"
}

install_bin_wrappers() {
    cp "`dirname $(readlink_f $scriptdir)`/lib/readlink_f.sh" "$root/bin/"

    get_shell_script > "$root/bin/arachni_shell"
    chmod +x "$root/bin/arachni_shell"
    echo "  * $root/bin/arachni_shell"

    get_test_script > "$root/bin/arachni_test"
    chmod +x "$root/bin/arachni_test"
    echo "  * $root/bin/arachni_test"

    cd $root/gems/bin
    for bin in arachni*; do
        echo "  * $root/bin/$bin => $root/gems/bin/$bin"
        get_wrapper_template "\$env_root/gems/bin/$bin" > "$root/bin/$bin"
        chmod +x "$root/bin/$bin"
    done
    cd - > /dev/null
}

echo
echo '# (1/5) Creating directories'
echo '---------------------------------'
setup_dirs

echo
echo '# (2/5) Installing dependencies'
echo '-----------------------------------'
install_libs

if [[ ! -d $clean_build ]] || [[ $update_clean_dir == true ]]; then
    mkdir -p $clean_build
    echo "==== Backing up clean build directory ($clean_build)."
    cp -R $usr_path $clean_build/
fi

echo
echo '# (3/5) Preparing the Ruby environment'
echo '-------------------------------------------'
prepare_ruby

echo
echo '# (4/5) Installing Arachni'
echo '-------------------------------'
install_arachni

echo
echo '# (5/5) Installing bin wrappers'
echo '------------------------------------'
install_bin_wrappers

echo
echo '# Cleaning up'
echo '----------------'
echo "  * Removing logs"
rm -rf "$root/logs"

echo "  * Removing sources"
rm -rf $src_path
rm -rf $root/usr/include/*

echo "  * Removing downloaded archives"
rm -rf $archives_path

echo "  * Removing docs"
rm -rf $root/usr/share/*
rm -rf $root/gems/doc/*

echo "  * Removing gem cache"
rm -rf $root/gems/cache/*

cp `dirname $scriptdir`/README.tpl $root/README
cp `dirname $scriptdir`/LICENSE.tpl $root/LICENSE

echo "  * Adjusting shebangs"
if [[ `uname` == "Darwin" ]]; then
    find $root/ -type f -exec sed -i '' 's/#!\/.*\/ruby/#!\/usr\/bin\/env ruby/g' {} \;
else
    find $root/ -type f -exec sed -i 's/#!\/.*\/ruby/#!\/usr\/bin\/env ruby/g' {} \;
fi

echo
cat<<EOF
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Build completed successfully!

You can add '$root/bin' to your path in order to be able to access the Arachni
executables from anywhere:

    echo 'export PATH=$root/bin:\$PATH' >> ~/.bash_profile
    source ~/.bash_profile

Useful info:
    * Homepage           - http://arachni-scanner.com
    * Blog               - http://arachni-scanner.com/blog
    * Documentation      - http://arachni-scanner.com/wiki
    * Support            - http://support.arachni-scanner.com
    * GitHub page        - http://github.com/Arachni/arachni
    * Code Documentation - http://rubydoc.info/github/Arachni/arachni
    * Author             - Tasos "Zapotek" Laskos (http://twitter.com/Zap0tek)
    * Twitter            - http://twitter.com/ArachniScanner
    * Copyright          - 2010-2012 Tasos Laskos
    * License            - Apache License v2

Have fun ;)

Cheers,
The Arachni team.

EOF
