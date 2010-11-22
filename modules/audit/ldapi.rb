=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules

#
# LDAP injection audit module.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
# @see http://cwe.mitre.org/data/definitions/90.html
# @see http://projects.webappsec.org/w/page/13246947/LDAP-Injection
# @see http://www.owasp.org/index.php/LDAP_injection
#
class LDAPInjection < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )

        # initialize the results array
        @__results = []
    end

    def prepare( )

        #
        # we make this a class variable and populate it only once
        # to reduce file IO
        #
        @@__regexps ||= []

        if @@__regexps.empty?
            read_file( 'regexps.txt' ) { |regexp| @@__regexps << regexp }
        end


        # prepare the strings that will hopefully cause the webapp
        # to output LDAP error messages
        @__injection_str = "#^($!@$)(()))******"

        @__opts = {
            :format => [ Format::APPEND ],
            :regexp => @@__regexps
        }

    end

    def run( )
        audit( @__injection_str, @__opts )
    end


    def self.info
        {
            :name           => 'LDAPInjection',
            :description    => %q{LDAP injection module},
            :elements       => [
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :references     => {
                'WASC'      => 'http://projects.webappsec.org/w/page/13246947/LDAP-Injection',
                'OWASP'     => 'http://www.owasp.org/index.php/LDAP_injection'
            },
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{LDAP Injection},
                :description => %q{LDAP queries can be injected into the web application.},
                :cwe         => '90',
                :severity    => Vulnerability::Severity::HIGH,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => ''
            }

        }
    end

end
end
end
