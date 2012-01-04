=begin
  $Id$

                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

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
# @version: 0.1.1
#
# @see http://cwe.mitre.org/data/definitions/90.html
# @see http://projects.webappsec.org/w/page/13246947/LDAP-Injection
# @see http://www.owasp.org/index.php/LDAP_injection
#
class LDAPInjection < Arachni::Module::Base

    include Arachni::Module::Utilities

    def prepare

        #
        # we make this a class variable and populate it only once
        # to reduce file IO
        #
        @@__errors ||= []

        if @@__errors.empty?
            read_file( 'errors.txt' ) { |error| @@__errors << error }
        end


        # prepare the strings that will hopefully cause the webapp
        # to output LDAP error messages
        @__injection_str = "#^($!@$)(()))******"

        @__opts = {
            :format    => [ Format::APPEND ],
            :substring => @@__errors
        }

    end

    def run
        audit( @__injection_str, @__opts )
    end


    def self.info
        {
            :name           => 'LDAPInjection',
            :description    => %q{It tries to force the web application to
                return LDAP error messages in order to discover failures
                in user input validation.},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE,
                Issue::Element::HEADER
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.1',
            :references     => {
                'WASC'      => 'http://projects.webappsec.org/w/page/13246947/LDAP-Injection',
                'OWASP'     => 'http://www.owasp.org/index.php/LDAP_injection'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{LDAP Injection},
                :description => %q{LDAP queries can be injected into the web application
                    which can be used to disclose sensitive data of affect the execution flow.},
                :tags        => [ 'ldap', 'injection', 'regexp' ],
                :cwe         => '90',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '',
                :remedy_guidance    => %q{User inputs must be validated and filtered
                    before being used in an LDAP query.},
                :remedy_code => ''
            }

        }
    end

end
end
end
