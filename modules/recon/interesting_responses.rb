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
# Logs all non 200 (OK) server responses.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
#
class InterestingResponses < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )

        # we need to run only once
        @@__ran ||= false
    end

    def run( )
        return if @@__ran

        print_status( "Listening..." )

        # tell the HTTP interface to cal this block every-time a request completes
        @http.on_complete {
            |res|
            __log_results( res ) if res.code != 200 && !res.body.empty?
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
            :version        => '0.1',
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{Interesting server response.},
                :description => %q{The server responded with a non 200 (OK) code. },
                :cwe         => '',
                :severity    => Vulnerability::Severity::INFORMATIONAL,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

    def __log_results( res )

        vuln = Vulnerability.new( {
            :var          => 'n/a',
            :url          => res.effective_url,
            :injected     => 'n/a',
            :method       => res.request.method.to_s.upcase,
            :id           => "Code: #{res.code.to_s}",
            :regexp       => 'n/a',
            :regexp_match => 'n/a',
            :elem         => Vulnerability::Element::SERVER,
            :response     => res.body,
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
            }
        }.merge( self.class.info ) )

        # register our results with the system
        register_results( [vuln] )

        # inform the user that we have a match
        print_ok( "Found an interesting response (Code: #{res.code.to_s})." )
    end

end
end
end
