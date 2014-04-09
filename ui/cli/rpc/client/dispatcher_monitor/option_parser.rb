=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative '../remote/option_parser'

module Arachni
module UI::CLI
module RPC
module Client
class DispatcherMonitor

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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
