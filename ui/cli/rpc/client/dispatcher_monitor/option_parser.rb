=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative '../remote/option_parser'

module Arachni
module UI::CLI
module RPC
module Client
class DispatcherMonitor

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class OptionParser < Client::Remote::OptionParser

    def after_parse
        options.dispatcher.url = ARGV.shift
    end

    def validate
        # Check for missing Dispatcher
        return if options.dispatcher.url

        print_error 'Missing DISPATCHER_URL option.'
        exit 1
    end

    def banner
        "Usage: #{$0} [options] DISPATCHER_URL"
    end

end
end
end
end
end
end
