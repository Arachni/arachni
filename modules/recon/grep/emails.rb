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

# Looks for and logs e-mail addresses.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.2
class Arachni::Modules::EMails < Arachni::Module::Base

    def run
        match_and_log( /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i ) do |email|
            return false if audited?( email )
            audited( email )
        end
    end

    def self.info
        {
            name:        'E-mail address',
            description: %q{Greps pages for disclosed e-mail addresses.},
            elements:    [ Element::BODY ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.2',
            targets:     %w(Generic),
            issue:       {
                name:            %q{E-mail address disclosure},
                description:     %q{Email addresses are typically found on 
                    'Contact us' pages, however they can also be found within
                    scripts or code comments of the application. They are used to
                    provide a legitimate means of contacting an organisation. As 
                    one of the initial steps in information gathering, cyber-
                    criminals will spider a website and using automated methods 
                    collect as many email addresses as possible, that they may 
                    then use in a social engineering attack against that user. 
                    Using the same automated methods, Arachni was able to detect 
                    one or more email addresses that were stored within the 
                    affected page.},
                cwe:             '200',
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{As a general rule, email addresses should be 
                    presented in such a way that it is hard for scripts to 
                    process them automatically. For example, 
                    'test@arachni-scanner.com' may become 
                    'test[at]yourdomain[dot]com'. Although this will force extra 
                    user interaction when utilising the address (changing [dot] 
                    to . etc) it will reduce the likelihood that these emails 
                    will be discovered by an automated process. To provide 
                    further protection against manual discovery, generic email 
                    addresses should be used. For example on a 'contact us' page 
                    'contactus@arachni-scanner.com' should be utilised instead 
                    of an individual's email address such as 
                    'john.doe@arachni-scanner.com'. Performing this extra step 
                    may reduce the likelihood of username enumeration for the 
                    domain.}
            },
            max_issues: 25
        }
    end

end
