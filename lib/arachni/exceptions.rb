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

#
# Arachni::Exceptions module<br/>
# It holds the framework's exceptions.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.1
#
module Exceptions

    def initialize( msg )
        super( msg )
    end


    class NoAuditOpts < StandardError
        include Exceptions

    end

    class NoMods < StandardError
        include Exceptions

    end

    class ComponentNotFound < StandardError
        include Exceptions

    end

    class ModNotFound < StandardError
        include Exceptions

    end

    class DepModNotFound < StandardError
        include Exceptions

    end

    class ReportNotFound < StandardError
        include Exceptions

    end

    class NoURL < StandardError
        include Exceptions

    end

    class InvalidURL < StandardError
        include Exceptions

    end

    class NoCookieJar < StandardError
        include Exceptions

    end

end

end
