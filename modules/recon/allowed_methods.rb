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
# Allowed HTTP methods recon module.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
# @see http://en.wikipedia.org/wiki/WebDAV
# @see http://www.webdav.org/specs/rfc4918.html
#
class AllowedMethods < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )
    end

    def prepare
        @@__ran ||= false
    end

    def run( )

        return if @@__ran

        print_status( "Checking..." )

        @http.request( URI( @page.url ).host, :method => :options ).on_complete {
            |res|
            __log_results( res )
        }
    end

    def self.info
        {
            :name           => 'AllowedMethods',
            :description    => %q{Checks for supported HTTP methods.},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :references     => {
            },
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{Allowed HTTP methods},
                :description => %q{},
                :cwe         => '',
                :severity    => Vulnerability::Severity::INFORMATIONAL,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }
        }
    end

    def __log_results( res )

        @@__ran = true
        methods = res.headers_hash['Allow']
        vuln = Vulnerability.new( {
            :var          => 'n/a',
            :url          => res.effective_url,
            :injected     => 'n/a',
            :method       => res.request.method.to_s.upcase,
            :id           => 'n/a',
            :regexp       => 'n/a',
            :regexp_match => methods,
            :elem         => 'n/a',
            :response     => res.body,
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
            }
        }.merge( self.class.info ) )

        # register our results with the system
        register_results( [vuln] )

        # inform the user that we have a match
        print_ok( methods )
    end

end
end
end
