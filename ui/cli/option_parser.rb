=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'optparse'
require_relative 'utilities'

module Arachni
module UI::CLI

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class OptionParser
    include UI::Output
    include UI::CLI::Utilities

    def initialize
        separator ''
        separator 'Generic'

        # This is CLI-related only and not a system option so we set the default here.
        options.datastore.report_path = options.paths.config['cli']['report_path']

        on( '-h', '--help', 'Output this message.' ) do
            puts parser
            exit
        end

        on( '--version', 'Show version information.' ) do
            puts "Arachni #{Arachni::VERSION} (#{RUBY_ENGINE} #{RUBY_VERSION}" <<
                     "p#{RUBY_PATCHLEVEL}) [#{RUBY_PLATFORM}]"
            exit
        end
    end

    def separator( *args )
        parser.separator( *args )
    end

    def on( *args, &block )
        parser.on( *args ) do |*bargs|
            begin
                block.call *bargs
            rescue => e
                print_bad "#{args.first.split( /\s/ ).first}: [#{e.class}] #{e}"
                exit 1
            end
        end
    end

    def banner
        "Usage: #{$0} [options]"
    end

    def parser
        @parser ||= ::OptionParser.new( banner, 27, '  ' )
    end

    def parse
        print_banner

        # Make the formatting a bit clearer with indentation for subsequent
        # description lines and empty lines between options.
        parser.top.each_option do |option|
            next if option.is_a? String
            option.desc.replace ([option.desc.shift] + option.desc.map { |l| "  #{l}" })
            option.desc << ' '
        end

        parser.parse!

        after_parse
        validate
    end

    # @abstract
    def after_parse
    end

    # @abstract
    def validate
    end

    def options
        Arachni::Options.instance
    end

    private

    def prepare_component_options( hash, argument )
        component_name, options_string = argument.split( ':', 2 )

        hash[component_name] = { }

        return hash if !options_string

        options_string.split( ',', ).each do |option|
            name, val = option.split( '=', 2 )
            hash[component_name][name] = val
        end

        hash
    end

    def paths_from_file( file )
        IO.read( file ).lines.map { |p| p.strip }
    end

end
end
end
