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
# HTTP PUT recon module.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class HTTP_PUT < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )

        @@__checked ||= Set.new
    end

    def run( )

        path = get_path( @page.url ) + 'Arachni-' + seed.to_s[0..4].to_s

        return if @@__checked.include?( path )
        @@__checked << path

        @http.request( path, :method => :put, :body => 'Created by Arachni.' ).on_complete {
            @http.get( path ).on_complete {
                |res|
                __log_results( res ) if res.body && res.body.substring?( 'Arachni' )
            }
        }
    end

    def self.info
        {
            :name           => 'HTTP PUT',
            :description    => %q{Checks if uploading files is possible using the HTTP PUT method.},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :references     => {},
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{HTTP PUT is enabled.},
                :description => %q{3rd parties can upload files to the web-server.},
                :tags        => [ 'http', 'methods', 'put', 'server' ],
                :cwe         => '650',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }
        }
    end

    def __log_results( res )

        issue = Issue.new( {
            :var          => 'n/a',
            :url          => res.effective_url,
            :injected     => 'n/a',
            :method       => res.request.method.to_s.upcase,
            :id           => 'n/a',
            :regexp       => 'n/a',
            :regexp_match => 'n/a',
            :elem         => Issue::Element::SERVER,
            :response     => res.body,
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
            }
        }.merge( self.class.info ) )

        # register our results with the system
        register_results( [issue] )

        print_ok( 'Request was accepted: ' + res.effective_url )
    end

end
end
end
