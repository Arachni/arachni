=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

require "#{Options.paths.root}ui/cli/output"

module UI

# RPC Output interface.
#
# Basically provides us with {#print_error error logging} and the ability to
# reroute all other messages to a logfile.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Output

    def print_error( str = '' )
        log_error( str )
        push_to_output_buffer( error: str )
    end

    def print_bad( str = '' )
        push_to_output_buffer( bad: str )
    end

    def print_status( str = '' )
        return if only_positives?
        push_to_output_buffer( status: str )
    end

    def print_info( str = '' )
        return if only_positives?
        push_to_output_buffer( info: str )
    end

    def print_ok( str = '' )
        push_to_output_buffer( ok: str )
    end

    def print_debug( str = '', level = 1 )
        return if !debug?( level )
        push_to_output_buffer( debug: str )
    end

    def print_debug_level_1( str = '' )
        print_debug( str, 1 )
    end

    def print_debug_level_2( str = '' )
        print_debug( str, 2 )
    end

    def print_debug_level_3( str = '' )
        print_debug( str, 3 )
    end

    def print_verbose( str = '' )
        return if !verbose?
        push_to_output_buffer( verbose: str )
    end

    def print_line( str = '' )
        return if only_positives?
        push_to_output_buffer( line: str )
    end

    def reroute_to_file( file )
        @@reroute_to_file = file
    end

    def reroute_to_file?
        @@reroute_to_file
    end

    private

    def push_to_output_buffer( msg )
        return if !@@reroute_to_file

        File.open( @@reroute_to_file, 'a+' ) do |f|
            type = msg.keys[0]
            str  = msg.values[0]

            f.write( "[#{Time.now.asctime}] [#{type}]  #{str}\n" )
        end
    end

    extend self

end

end
end
