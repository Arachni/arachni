=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module UI

# Provides a blackhole output interface which is loaded when Arachni
# is not driven by a UI but being scripted.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
    end
    reset_output_options

    def print_error(*)
    end

    def print_exception(*)
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

    def print_debug_level_1(*)
    end

    def print_debug_level_2(*)
    end

    def print_debug_level_3(*)
    end

    def print_debug_level_4(*)
    end

    def print_debug_backtrace(*)
    end

    def print_error_backtrace(*)
    end

    def debug_level_1?
        debug? 1
    end
    def debug_level_2?
        debug? 2
    end
    def debug_level_3?
        debug? 3
    end
    def debug_level_4?
        debug? 4
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

    def debug_on(*)
    end
    alias :debug :debug_on

    def debug_off
    end

    def debug?(*)
    end

    1.upto( 3 ) do |i|
        define_method( "debug_level_#{i}?" ) {}
        define_method( "debug_level_#{i}" ) {}
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
