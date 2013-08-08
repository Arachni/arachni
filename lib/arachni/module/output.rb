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
