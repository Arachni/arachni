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

module Modules

#
# SQL Injection audit module.<br/>
# It audits links, forms and cookies.
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.5
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://unixwiz.net/techtips/sql-injection.html
# @see http://en.wikipedia.org/wiki/SQL_injection
# @see http://www.securiteam.com/securityreviews/5DP0N1P76E.html
# @see http://www.owasp.org/index.php/SQL_Injection
#
class SQLInjection < Arachni::Module::Base

    include Arachni::Module::Utilities

    def prepare

        #
        # it's better to save big arrays to a file
        # a big array is ugly, messy and can't be updated as easily
        #
        # but don't open the file yourself, use get_data_file( filename )
        # with a block and read each line
        #
        # keep your files under modules/<modtype>/<modname>/
        #

        #
        # we make this a class variable and populate it only once
        # to reduce file IO
        #
        @@__regexps ||= []

        if @@__regexps.empty?
            read_file( 'regexp_ids.txt' ) { |regexp| @@__regexps << regexp }
        end

        # prepare the string that will hopefully cause the webapp
        # to output SQL error messages
        @__injection_str = [
            '\'`--',
            ')'
            ]

        @__opts = {
            :format => [ Format::APPEND ],
            :regexp => @@__regexps,
            :param_flip => true
        }

    end

    def run
        @__injection_str.each { |str| audit( str, @__opts ) }
    end


    def self.info
        {
            :name           => 'SQLInjection',
            :description    => %q{SQL injection recon module},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE,
                Issue::Element::HEADER
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1.5',
            :references     => {
                'UnixWiz'    => 'http://unixwiz.net/techtips/sql-injection.html',
                'Wikipedia'  => 'http://en.wikipedia.org/wiki/SQL_injection',
                'SecuriTeam' => 'http://www.securiteam.com/securityreviews/5DP0N1P76E.html',
                'OWASP'      => 'http://www.owasp.org/index.php/SQL_Injection'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{SQL Injection},
                :description => %q{SQL code can be injected into the web application.},
                :tags        => [ 'sql','injection', 'regexp', 'database', 'error' ],
                :cwe         => '89',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '9.0',
                :remedy_guidance    => 'User inputs must be validated and filtered
                    before being included in database queries.',
                :remedy_code => '',
                :metasploitable => 'unix/webapp/arachni_sqlmap'
            }

        }
    end

end
end
end
