=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

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
# @version: 0.3
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://capec.mitre.org/data/definitions/7.html
# @see http://www.owasp.org/index.php/Blind_SQL_Injection
#
class BlindrDiffSQLInjection < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )
    end

    def prepare( )
        # used for redundancy checks
        @@__audited ||= Set.new
    end

    def run( )

        opts = {}

        opts[:faults] = [ '\'"`' ]

        opts[:bools] = []
        [ '\'', '"', '' ].each {
            |str|
            opts[:bools] << '%s and %s1' % [str, str]
        }


        [ @page.links | @page.forms ].flatten.each {
            |elem|
            next if __audited?( elem )
            audit_rdiff( elem, opts )
            __auditted!( elem )
        }

    end

    def __auditted!( elem )
        @@__audited << __audit_id( elem )
    end

    def __audited?( elem )
        @@__audited.include?( __audit_id( elem ) )
    end

    def __audit_id( elem )
        elem.action + elem.auditable.keys.to_s
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
                Issue::Element::FORM
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version         => '0.3',
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
