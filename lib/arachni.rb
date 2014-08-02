=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

require 'rubygems'
require 'bundler/setup'

def ap( obj )
    super obj, raw: true
end

module Arachni

    class <<self

        def null_device
            Gem.win_platform? ? 'NUL' : '/dev/null'
        end

        # @return   [Bool]
        def jruby?
            RUBY_PLATFORM == 'java'
        end

        # @return   [Bool]
        def windows?
            Gem.win_platform?
        end

        # @return   [Bool]
        #   `true` if the `ARACHNI_PROFILE` env variable is set, `false` otherwise.
        def profile?
            !!ENV['ARACHNI_PROFILER']
        end

    end

end

require_relative 'arachni/version'
require_relative 'arachni/banner'

# If there's no UI driving us then there's no output interface.
# Chances are that someone is using Arachni as a Ruby lib so there's no
# need for a functional output interface, so provide non-functional one.
#
# However, functional or not, the system does depend on one being available.
if !Arachni.constants.include?( :UI )
    require_relative 'arachni/ui/foo/output'
end

require_relative 'arachni/framework'
