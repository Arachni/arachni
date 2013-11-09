=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

require 'rubygems'
require 'bundler/setup'

def ap( obj )
    super obj, raw: true
end

module Arachni
    # @return   [Bool]
    #   `true` if the `ARACHNI_PROFILE` env variable is set, `false` otherwise.
    def self.profile?
        !!ENV['ARACHNI_PROFILE']
    end
end

require_relative 'arachni/version'
require_relative 'arachni/banner'

#
# If there's no UI driving us then there's no output interface.
#
# Chances are that someone is using Arachni as a Ruby lib so there's no
# need for a functional output interface, so provide non-functional one.
#
if !Arachni.constants.include?( :UI )
    require_relative 'arachni/ui/foo/output'
end

require_relative 'arachni/framework'
