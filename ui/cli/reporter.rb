=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative '../../lib/arachni'
require_relative 'reporter/option_parser'
require_relative 'utilities'

module Arachni
module UI::CLI

# Provides a command line interface to the {Arachni::Report::Manager}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Reporter
    include UI::Output
    include Utilities

    def initialize
        @reporters = Arachni::Reporter::Manager.new
        run
    end

    private

    def run
        parser = OptionParser.new
        parser.reporter
        parser.parse

        reporters = parser.reporters
        reporters = { 'stdout' => {} } if reporters.empty?

        begin
            report = ScanReport.load( parser.report_path )

            reports.each do |name, options|
                @reporters.run( name, report, options )
            end
        rescue => e
            print_error e
            print_error_backtrace e
        end
    end

end
end
end
