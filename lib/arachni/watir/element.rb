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

module Watir
    class Element
        def attributes
            browser.execute_script(
                %Q[
                    var s = [];
                    var attrs = arguments[0].attributes;
                    for( var l = 0; l < attrs.length; ++l ) {
                        s.push( attrs[l].name );
                    }
                    return s;
                ],
                self
            )
        end
    end
end
