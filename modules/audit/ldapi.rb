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

        @__regexps_file = 'regexps.txt'

        # prepare the strings that will hopefully cause the webapp
        # to output LDAP error messages
        @__injection_strs = [
            "#^($!@$)(()))******"
        ]

        @__opts = {
            :format => [ Format::APPEND ]
        }

    end

    def run( )

        @__injection_strs.each {
            |str|
            audit( str, @__opts ) {
                |res, var, opts|
                __log_results( opts, var, res )
            }
        }
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

    private

    def __log_results( opts, var, res )

        elem     = opts[:element]
        injected = opts[:injected]
        url      = res.effective_url

        # iterate through the regular expressions in @__regexps_file
        # and try to match them with the body of the HTTP response
        read_file( @__regexps_file ) {
            |id|

            # strip whitespace from the regexp
            id = id.strip

            # just to make sure...
            if id.size == 0 then next end

            # create a regular expression from the regexp strings
            id_regex = Regexp.new( id )

            # try to match them with the body of the HTTP response,
            # if it matches we have a positive result
            if ( ( match = res.body.scan( id_regex )[0] ) &&
                 res.body.scan( id_regex )[0].size > 0 )

                # if we didn't cause the error tell the user that manual
                # verification is required
                verification = false
                if( @page.html.scan( id_regex )[0] )
                    verification = true
                end

                # append the result to the results array
                @__results << Vulnerability.new( {
                        :var          => var,
                        :url          => url,
                        :method       => res.request.method.to_s,
                        :opts         => opts,
                        :injected     => injected,
                        :id           => id,
                        :regexp       => id_regex.to_s,
                        :regexp_match => match,
                        :elem         => elem,
                        :response     => res.body,
                        :verification => verification,
                        :headers      => {
                            :request    => res.request.headers,
                            :response   => res.headers,
                        }

                    }.merge( self.class.info )
                )

                # inform the user that we have a match
                print_ok( "In #{elem} var #{var} ( #{url} )" )

                # give the user some more info if he wants
                print_verbose( "Injected str:\t" + injected )
                print_verbose( "ID str:\t\t" + id )
                print_verbose( "Matched regex:\t" + id_regex.to_s )
                print_verbose( '---------' ) if only_positives?

                # register our results with the framework
                register_results( @__results )

                # since a regexp tested positive
                # we don't need to test for the rest
                return true
            end

        }
    end

end
end
end
