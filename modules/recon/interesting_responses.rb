=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'digest/md5'

module Arachni
module Modules

#
# Logs all non 200 (OK) and non 404 server responses.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.3
#
#
class InterestingResponses < Arachni::Module::Base

    include Arachni::Module::Utilities

    IGNORE_CODES = [
        200,
        404
    ]

    def prepare
        # we need to run only once
        @@__ran ||= false
    end

    def run
        return if @@__ran

        print_status( "Listening..." )

        # tell the HTTP interface to cal this block every-time a request completes
        @http.add_on_complete {
            |res|
            __log_results( res ) if !IGNORE_CODES.include?( res.code ) && !res.body.empty?
        }

    end

    def clean_up
        @@__ran = true
    end

    def self.info
        {
            :name           => 'Interesting responses',
            :description    => %q{Logs all non 200 (OK) server responses.},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.3',
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Interesting server response.},
                :description => %q{The server responded with a non 200 (OK) code. },
                :tags        => [ 'interesting', 'response', 'server' ],
                :cwe         => '',
                :severity    => Issue::Severity::INFORMATIONAL,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

    def __log_results( res )

        @@_loged ||= {
            :paths   => Set.new,
            :digests => Set.new
        }

        digest = Digest::MD5.hexdigest( res.body )
        path   = URI( res.effective_url ).path

        return if @@_loged[:paths].include?( path ) ||
            @@_loged[:digests].include?( digest )

        @@_loged[:paths]   << path
        @@_loged[:digests] << digest

        log_issue(
            :url          => res.effective_url,
            :method       => res.request.method.to_s.upcase,
            :id           => "Code: #{res.code.to_s}",
            :elem         => Issue::Element::SERVER,
            :response     => res.body,
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
            }
        )

        # inform the user that we have a match
        print_ok( "Found an interesting response (Code: #{res.code.to_s})." )
    end

end
end
end
