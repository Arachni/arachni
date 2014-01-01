=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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

require Options.dir['lib'] + 'module/manager'

module RPC
class Server
module Module

#
# We need to extend the original Manager and re-declare its inherited methods
# which are required over RPC.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Manager < ::Arachni::Module::Manager

    # make these inherited methods visible again
    private :load, :available, :loaded, :load_all
    public :load, :available, :loaded, :load_all

    def load( mods )
        @opts.mods = super( mods )
    end

end

end
end
end
end
