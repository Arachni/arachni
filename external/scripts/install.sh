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
# Doesn't do all that yet though...
#
# Requirements:
#   * curl
#   * build-essential
#   * git
#   * libsqlite3-dev
#   * libxml2-dev
#
# Install them with:
#   sudo apt-get install curl build-essential git libsqlite3-dev libxml2-dev
#

# install RVM
bash -s stable < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer) && \

# load RVM
source ~/.rvm/scripts/rvm && \

# install all lib deps
rvm pkg install iconv && \
rvm pkg install zlib && \
rvm pkg install curl && \
rvm pkg install openssl && \
# rvm pkg install libxml2 && \

# libxslt is a bit tricky, needs some extra work
rvm pkg install libxslt && \
cd ~/.rvm/src/libxslt-* && \
./configure --prefix=~/.rvm/usr --with-libxml-prefix=~/.rvm/usr && make && make install && \
cd - && \

rvm pkg install libyaml && \

# download and install Ruby
rvm install ruby-1.9.3-p125 && \

# setup the Ruby env
# rvm use 1.9.3-p125 && rvm gemset create arachni && rvm gemset use arachni  && \

# clone the Arachni repo
git clone git://github.com/Zapotek/arachni.git && \

# install Arachni and its deps
cd arachni && \
git checkout experimental && \
cd . && \
gem install bundle && \
bundle install && \

# run the specs to make sure that everything's working
rake spec
