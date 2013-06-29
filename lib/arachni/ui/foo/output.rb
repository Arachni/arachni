=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni
module UI

#
# Provides a blackhole output interface which is loaded when Arachni
# is not driven by a UI but being scripted.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Output

    def self.reset_output_options
        # verbosity flag
        #
        # if it's on verbose messages will be enabled
        @@verbose = false

        # debug flag
        #
        # if it's on debugging messages will be enabled
        @@debug   = false

        # only_positives flag
        #
        # if it's on status messages will be disabled
        @@only_positives  = false

        @@mute  = false
    end
    reset_output_options

    def print_error(*)
    end

    def print_bad(*)
    end

    def print_status(*)
    end

    def print_info(*)
    end

    def print_ok(*)
    end

    def print_debug(*)
    end

    def print_debug_pp(*)
    end

    def print_debug_backtrace(*)
    end

    def print_error_backtrace(*)
    end

    def print_verbose(*)
    end

    def print_line(*)
    end

    def verbose
    end

    def verbose?
    end

    def debug_on
    end
    alias :debug :debug_on

    def debug_off
    end

    def debug?
    end

    def only_positives
    end

    def disable_only_positives
    end

    def only_positives?
    end

    def mute
    end

    def unmute
    end

    def muted?
    end

    extend self
end

end
end
