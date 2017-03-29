=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'rubygems'
require 'bundler/setup'
require 'concurrent'
require 'pp'
require 'ap'

def ap( obj )
    super obj, raw: true
end

module Arachni

    class <<self

        # Runs a minor GC to collect young, short-lived objects.
        #
        # Generally called after analysis operations that generate a lot of
        # new temporary objects.
        def collect_young_objects
            GC.start( full_mark: false )
        end

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

        if Arachni.windows?
            require 'find'
            require 'fileutils'
            require 'Win32API'
            require 'win32ole'

            def get_long_win32_filename( short_name )
                short_name = short_name.dup
                max_path   = 1024
                long_name  = ' ' * max_path

                lfn_size = Win32API.new(
                    "kernel32", 
                    "GetLongPathName",
                    ['P','P','L'],
                    'L'
                ).call( short_name, long_name, max_path )

                (1..max_path).include?( lfn_size ) ? 
                    long_name[0..lfn_size-1] : short_name
            end 
        else
            def get_long_win32_filename( short_name )
                short_name
            end
        end
    end

end

if !Arachni.jruby?
    require 'oj_mimic_json'
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
