=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

require_relative '../../lib/arachni'
require_relative 'reporter/option_parser'
require_relative 'utilities'

module Arachni
module UI::CLI

# Provides a command line interface to the {Arachni::Report::Manager}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
            report = Report.load( parser.report_path )

            reporters.each do |name, options|
                @reporters.run( name, report, options )
            end
        rescue => e
            print_exception e
        end
    end

end
end
end
