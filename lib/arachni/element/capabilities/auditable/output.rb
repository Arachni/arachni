=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Element::Capabilities
module Auditable

# Delegate output related methods to the {Auditable#auditor}.
module Output

    def debug?
        auditor.debug? rescue false
    end

    def print_error( str = '' )
        auditor.print_error( str ) if !orphan?
    end

    def print_status( str = '' )
        auditor.print_status( str ) if !orphan?
    end

    def print_info( str = '' )
        auditor.print_info( str ) if !orphan?
    end

    def print_line( str = '' )
        auditor.print_line( str ) if !orphan?
    end

    def print_ok( str = '' )
        auditor.print_ok( str ) if !orphan?
    end

    def print_bad( str = '' )
        auditor.print_bad( str ) if !orphan?
    end

    def print_debug( str = '' )
        auditor.print_debug( str ) if !orphan?
    end

    def print_debug_backtrace( str = '' )
        auditor.print_debug_backtrace( str ) if !orphan?
    end

    def print_error_backtrace( str = '' )
        auditor.print_error_backtrace( str ) if !orphan?
    end

end

end
end
end
