=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Plugin

# Will be extended by plugin formatters which provide plugin data formatting
# for the reports.
#
# Plugin formatters will be in turn ran by {Arachni::Report::Bas#format_plugin_results}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Formatter
    include UI::Output

    attr_reader :parent
    attr_reader :report
    attr_reader :results
    attr_reader :description

    def initialize( parent, report, plugin_data )
        @parent       = parent
        @report       = report
        @results      = plugin_data[:results]
        @description  = plugin_data[:description]
    end

    # @abstract
    def run
    end

end

end
end
