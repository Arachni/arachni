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

#
# Left here for compatibility reasons, has been obsoleted by the xss_path module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Arachni::Modules::XSSURI < Arachni::Module::Base

    def prepare
        if framework && !framework.modules.keys.include?( 'xss_path' )
            @mod = framework.modules['xss_path'].new( page, framework )
            @mod.prepare
        end
    end

    def run
        print_bad 'Module has been obsoleted and will eventually be removed.'
        print_bad 'Please remove it from any profiles or scripts you may have created.'
        print_bad '-- Running \'xss_path\' instead.'
        @mod.run if @mod
    end

    def clean_up
        @mod.clean_up if @mod
    end

    def self.info
        {
            name:        'XSSURI',
            description: %q{Compatibility module, will load and run xss_path instead.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0'
        }
    end

end
