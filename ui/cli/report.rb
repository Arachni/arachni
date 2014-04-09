=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative '../../lib/arachni'
require_relative 'report/option_parser'
require_relative 'utilities'

module Arachni
module UI::CLI

# Provides a command line interface to the {Arachni::Report::Manager}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Report
    include UI::Output
    include Utilities

    def initialize
        @reports = Arachni::Report::Manager.new
        run
    end

    private

    def run
        parser = OptionParser.new
        parser.report
        parser.parse

        reports = parser.reports
        reports = { 'stdout' => {} } if reports.empty?

        begin
            report = AuditStore.load( parser.report_path )

            reports.each do |name, options|
                @reports.run( name, report, options )
            end
        rescue => e
            print_error e
            print_error_backtrace e
        end
    end

end
end
end
