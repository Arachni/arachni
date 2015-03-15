=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
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
