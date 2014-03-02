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
# @version  0.4
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
            version:     '0.4',
            targets:     %w(Generic),
            references: {
                'CWE' => 'http://cwe.mitre.org/data/definitions/200.html'
            },
            issue:       {
                name:            %q{CVS/SVN user disclosure},
                description:     %q{Concurrent Version System (CVS) and 
                    Subversion (SVN) provide a method for application developers 
                    to control different versions of their code. Occasionally, 
                    the developer's version or user information can be stored 
                    incorrectly within the code and may be visible to the end 
                    user (Either in the HTML or code comments). As one of the 
                    initial steps in information gathering, cyber-criminals will 
                    spider a website and using automated methods attempt to 
                    discover any CVS/SVN information that may be present in the 
                    page. This will aid them in developing a better 
                    understanding of the deployed application (potentially 
                    through the disclosure of version information), or it may 
                    assist in further information gathering or social 
                    engineering attacks. Using the same automated methods, 
                    Arachni was able to detect CVS or SVN details stored within 
                    the affected page.},
                cwe:             '200',
                severity:        Severity::LOW,
                remedy_guidance: %q{CVS and/or SVN information should not be 
                    displayed to the end user. This can be achieved by removing 
                    this information all together prior to deployment, or by 
                    putting this information into a server side (PHP, ASP, JSP, 
                    etc) code comment block as opposed to a HTML code comment.},
            },
            max_issues: 25
        }
    end

end
