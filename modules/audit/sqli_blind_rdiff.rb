=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Modules

#
# Blind SQL injection audit module
#
# It uses reverse-diff analysis of HTML code in order to determine successful
# blind SQL injections.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.3.1
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://capec.mitre.org/data/definitions/7.html
# @see http://www.owasp.org/index.php/Blind_SQL_Injection
#
class BlindrDiffSQLInjection < Arachni::Module::Base

    include Arachni::Module::Utilities

    def prepare
        @@__bools ||= []

        if @@__bools.empty?
            read_file( 'payloads.txt' ) {
                |str|

                [ '\'', '"', '' ].each {
                    |quote|
                    @@__bools << str.gsub( '%q%', quote )
                }
            }
        end
    end

    def run
        opts = {}

        # fault injection seeds
        opts[:faults] = [ '\'"`' ]
        # boolean injection seeds
        opts[:bools] = @@__bools

        audit_rdiff( opts )
    end

    def self.info
        {
            :name           => 'Blind (rDiff) SQL Injection',
            :description    => %q{It uses rDiff analysis to decide how different inputs affect
                the behavior of the the web pages.
                Using that as a basis it extrapolates about what inputs are vulnerable to blind SQL injection.
                (Note: This module may get confused by certain types of XSS vulnerabilities.
                    If this module returns a positive result you should investigate nonetheless.)},
            :elements       => [
                Issue::Element::LINK,
                Issue::Element::FORM,
                Issue::Element::COOKIE
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version         => '0.3.1',
            :references      => {
                'OWASP'      => 'http://www.owasp.org/index.php/Blind_SQL_Injection',
                'MITRE - CAPEC' => 'http://capec.mitre.org/data/definitions/7.html'
            },
            :targets        => { 'Generic' => 'all' },

            :issue   => {
                :name        => %q{Blind SQL Injection},
                :description => %q{SQL code can be injected into the web application
                    even though it may not be obvious due to suppression of error messages.},
                :tags        => [ 'sql', 'blind', 'rdiff', 'injection', 'database' ],
                :cwe         => '89',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '9.0',
                :remedy_guidance    => %q{Suppression of error messages leads to
                    security through obscurity which is not a good practise.
                    The web application needs to enforce stronger validation
                    on user inputs.},
                :remedy_code => '',
                :metasploitable => 'unix/webapp/arachni_sqlmap'
            }

        }
    end

end
end
end
