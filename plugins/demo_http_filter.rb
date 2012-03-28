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
module Plugins

#
# Shows how to intercept HTTP calls and optionally modify them.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class DemoHTTPFilter < Arachni::Plugin::Base

    def run
        #
        # If this block returns one or more request objects these will be
        # queued instead of the original.
        #
        # Be careful though, the original is passed by ref so modifying it
        # in place will affect it.
        #
        @framework.http.add_on_queue {
            |request, async|
            # empty params of all requests
            # request.params = { }

            # return the request to be queued
            # request
        }
    end

    def self.info
        {
            :name           => 'Demo HTTP Filter',
            :description    => %q{Shows how to intercept HTTP calls and optionally modify them.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            # this should be run before all else in order to get the hook in early
            :order          => 0
        }
    end

end

end
end
