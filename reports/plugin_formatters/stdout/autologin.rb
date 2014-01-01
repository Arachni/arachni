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

class Arachni::Reports::Stdout

#
# Stdout formatter for the results of the AutoLogin plugin
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class PluginFormatters::AutoLogin < Arachni::Plugin::Formatter

    def run
        print_ok results[:msg]

        return if !results[:cookies]
        print_info 'Cookies set to:'
        results[:cookies].each_pair { |name, val| print_info "    * #{name} = #{val}" }
    end

end
end
