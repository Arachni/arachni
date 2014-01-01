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
# CVS/SVN users recon module.
#
# Scans every page for CVS/SVN users.
#
# @author   Tasos Laskos <tasos.laskos@gmail.com>
# @version  0.3
#
class Arachni::Modules::CvsSvnUsers < Arachni::Module::Base

    def self.regexps
        @regexps ||= [
            /\$Author: (\w+) \$/,
            /\$Locker: (\w+) \$/,
            /\$Header: .* (\w+) Exp \$/,
            /\$Id: .* (\w+) Exp \$/,
            /\$Header: .* (\w+) (?<!Exp )\$/,
            /\$Id: .* (\w+) (?<!Exp )\$/
        ]
    end

    def run
        match_and_log( self.class.regexps )
    end

    def self.info
        {
            name:        'CVS/SVN users',
            description: %q{Scans every page for CVS/SVN users.},
            elements:    [ Element::BODY ],
            author:      'Tasos Laskos <tasos.laskos@gmail.com>',
            version:     '0.3',
            targets:     %w(Generic),
            references: {
                'CWE' => 'http://cwe.mitre.org/data/definitions/200.html'
            },
            issue:       {
                name:            %q{CVS/SVN user disclosure},
                description:     %q{A CVS or SVN user is disclosed in the body of the HTML page.},
                cwe:             '200',
                severity:        Severity::LOW,
                remedy_guidance: %q{Remove all CVS and SVN users from the body of the HTML page.},
            },
            max_issues: 25
        }
    end

end
