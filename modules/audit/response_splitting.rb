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
# HTTP Response Splitting audit module.
#
# It audits links, forms and cookies.
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.5
#
# @see http://cwe.mitre.org/data/definitions/20.html
# @see http://www.owasp.org/index.php/HTTP_Response_Splitting
# @see http://www.securiteam.com/securityreviews/5WP0E2KFGK.html
#
class ResponseSplitting < Arachni::Module::Base

    def initialize( page )
        super( page )

        # initialize the header
        @__header = ''

        # initialize the array that will hold the results
        @results = []
    end

    def prepare( )

        # the header to inject...
        # what we will check for in the response header
        # is the existence of the "x-crlf-safe" field.
        # if we find it it means that the attack was succesful
        # thus site is vulnerable.
        @__header = "\r\nX-CRLF-Safe: no"
    end

    def run( )

        # try to inject the headers into all vectors
        # and pass a block that will check for a positive result
        audit( @__header ) {
            |res, opts|
            if res.headers_hash['X-CRLF-Safe'] &&
               !res.headers_hash['X-CRLF-Safe'].empty?

                opts[:injected] = URI.encode( opts[:injected] )
                log( opts, res )
            end
        }
    end


    def self.info
        {
            :name           => 'ResponseSplitting',
            :description    => %q{Tries to inject some data into the webapp and figure out
                if any of them end up in the response header.},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE,
                Issue::Element::HEADER
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1.5',
            :references     => {
                 'SecuriTeam'    => 'http://www.securiteam.com/securityreviews/5WP0E2KFGK.html',
                 'OWASP'         => 'http://www.owasp.org/index.php/HTTP_Response_Splitting'
            },
            :targets        => { 'Generic' => 'all' },

            :issue   => {
                :name        => %q{Response splitting},
                :description => %q{The web application includes user input
                     in the response HTTP header.},
                :cwe         => '20',
                :severity    => Issue::Severity::MEDIUM,
                :cvssv2       => '5.0',
                :remedy_guidance    => %q{User inputs must be validated and filtered
                    before being included as part of the HTTP response headers.},
                :remedy_code => '',
            }

        }
    end

end
end
end
