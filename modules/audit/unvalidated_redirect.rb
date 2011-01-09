=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules

#
# Unvalidated redirect audit module.
#
# It audits links, forms and cookies, injects URLs and checks
# the Location header field to determnine whether the attack was successful.
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
# @see http://www.owasp.org/index.php/Top_10_2010-A10-Unvalidated_Redirects_and_Forwards
#
class UnvalidatedRedirect < Arachni::Module::Base

    def initialize( page )
        super( page )

        # initialize the array that will hold the results
        @results = []
    end

    def prepare( )
        @__urls = [
          'www.arachni-boogie-woogie.com',
          'http://www.arachni-boogie-woogie.com',
        ]
    end

    def run( )
        @__urls.each {
            |url|

            audit( url ) {
                |res, opts|
                __log_results( res, opts, url )
            }
        }
    end


    def self.info
        {
            :name           => 'UnvalidatedRedirect',
            :description    => %q{Injects URLs and checks the Location header field
                to determnine whether the attack was successful.},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE
            ],
            :author         => 'zapotek',
            :version        => '0.1',
            :references     => {
                 'OWASP Top 10 2010' => 'http://www.owasp.org/index.php/Top_10_2010-A10-Unvalidated_Redirects_and_Forwards'
            },
            :targets        => { 'Generic' => 'all' },

            :issue   => {
                :name        => %q{Unvalidated redirect},
                :description => %q{The web application redirects users to unvalidated URLs.},
                :cwe         => '819',
                :severity    => Issue::Severity::MEDIUM,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

    private

    def __log_results( res, opts, url )


        if( res.headers_hash['Location'] == url )

            var = opts[:altered]
            @results << Issue.new( {
                    :var          => var,
                    :url          => res.effective_url,
                    :injected     => url,
                    :id           => '\'Location: ' + url + '\'',
                    :regexp       => 'n/a',
                    :regexp_match => 'n/a',
                    :elem         => opts[:element],
                    :response     => res.body,
                    :headers      => {
                        :request    => res.request.headers,
                        :response   => res.headers,
                    }
                }.merge( self.class.info )
            )

            print_ok( "In #{opts[:element]} var '#{var}' ( #{url} )" )

            # register our results with the system
            register_results( @results )
        end
    end

end
end
end
