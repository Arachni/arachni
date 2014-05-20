=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
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

    def included( base )
        base.extend ClassMethods
    end

    module ClassMethods
        def personalize_output
            @personalize_output = true
        end

        def personalize_output?
            @personalize_output
        end
    end

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

    def verbose_on
    end
    alias :verbose :verbose_on

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
