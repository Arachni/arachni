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
# HTTP PUT recon module.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.3
#
class HTTP_PUT < Arachni::Module::Base

    include Arachni::Module::Utilities

    def prepare
        @@__checked ||= Set.new
    end

    def run
        path = get_path( @page.url ) + 'Arachni-' + seed.to_s[0..4].to_s
        return if @@__checked.include?( path )
        @@__checked << path

        body = 'Created by Arachni. PUT' + seed

        @http.request( path, :method => :put, :body => body ).on_complete {
            |res|
            next if res.code != 201
            @http.get( path ).on_complete {
                |res|
                __log_results( res ) if res.body && res.body.substring?( 'PUT' + seed )
            }
        }
    end

    def self.info
        {
            :name           => 'HTTP PUT',
            :description    => %q{Checks if uploading files is possible using the HTTP PUT method.},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.3',
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

        log_issue(
            :url          => res.effective_url,
            :method       => res.request.method.to_s.upcase,
            :elem         => Issue::Element::SERVER,
            :response     => res.body,
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
            }
        )

        print_ok( 'File has been created: ' + res.effective_url )
    end

end
end
end
