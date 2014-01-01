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

#
# Looks for HTML "object" tags.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
class Arachni::Modules::HTMLObjects < Arachni::Module::Base

    def self.regexp
        @regexp ||= /<object(.*)>(.*)<\/object>/im
    end

    def run
        match_and_log( self.class.regexp ) { |m| m && !m.empty? }
    end

    def self.info
        description = %q{Logs the existence of HTML object tags.
                Since Arachni can't execute things like Java Applets and Flash
                this serves as a heads-up to the penetration tester to review
                the objects in question using a different method.}
        {
            name:        'HTML objects',
            description: description,
            elements:    [ Element::BODY ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.1',
            targets:     %w(Generic),
            issue:       {
                name:        %q{HTML object},
                cwe:         '200',
                description: description,
                severity:    Severity::INFORMATIONAL
            },
            max_issues: 25
        }
    end

end
