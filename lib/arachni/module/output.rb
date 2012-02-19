=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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
module Module


#
# Provides output functionality to the modules via the {Arachni::UI::Output}<br/>
# prepending the module name to the output message.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version 0.1
#
module Output

    include Arachni::UI::Output

    alias :o_print_error    :print_error
    alias :o_print_bad      :print_bad
    alias :o_print_status   :print_status
    alias :o_print_info     :print_info
    alias :o_print_ok       :print_ok
    alias :o_print_debug    :print_debug
    alias :o_print_verbose  :print_verbose
    alias :o_print_line     :print_line

    def print_error( str = '' )
        o_print_error( self.class.info[:name] + ": " + str )
    end

    def print_bad( str = '', out = $stdout )
        o_print_bad( self.class.info[:name] + ": " + str )
    end

    def print_status( str = '' )
        o_print_status( self.class.info[:name] + ": " + str )
    end

    def print_info( str = '' )
        o_print_info( self.class.info[:name] + ": " + str )
    end

    def print_ok( str = '' )
        o_print_ok( self.class.info[:name] + ": " + str )
    end

    def print_debug( str = '' )
        o_print_debug( self.class.info[:name] + ": " + str )
    end

    def print_verbose( str = '' )
        o_print_verbose( self.class.info[:name] + ": " + str )
    end

    def print_line( str = '' )
        o_print_line( self.class.info[:name] + ": " + str )
    end

end

end
end
