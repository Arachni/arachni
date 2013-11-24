=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Module

#
# Provides output functionality to the modules via the {Arachni::UI::Output}<br/>
# prepending the module name to the output message.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Output
    include UI::Output

    def print_error( str = '' )
        super "#{fancy_name}: #{str}"
    end

    def print_bad( str = '', out = $stdout )
        super "#{fancy_name}: #{str}"
    end

    def print_status( str = '' )
        super "#{fancy_name}: #{str}"
    end

    def print_info( str = '' )
        super "#{fancy_name}: #{str}"
    end

    def print_ok( str = '' )
        super "#{fancy_name}: #{str}"
    end

    def print_debug( str = '' )
        super "#{fancy_name}: #{str}"
    end

    def print_verbose( str = '' )
        super "#{fancy_name}: #{str}"
    end

    def print_line( str = '' )
        super "#{fancy_name}: #{str}"
    end

    def fancy_name
        @fancy_name ||= self.class.info[:name]
    end

end

end
end
