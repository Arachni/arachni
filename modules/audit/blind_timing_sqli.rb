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
# Blind SQL Injection module using timing attacks.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://capec.mitre.org/data/definitions/7.html
# @see http://www.owasp.org/index.php/Blind_SQL_Injection
#
class BlindTimingSQLInjection < Arachni::Module::Base

    include Arachni::Module::Utilities

    TIME = 6

    def initialize( page )
        super( page )
    end

    def prepare( )

        @@__injection_str ||= []

        if @@__injection_str.empty?
            read_file( 'payloads.txt' ) {
                |str|
                @@__injection_str << str.gsub( '__TIME__', TIME.to_s )
            }
        end

        @__opts = {
            :format => [ Format::STRAIGHT, Format::APPEND ]
        }

    end

    def run( )
        @@__injection_str.each {
            |str|
            audit( str, @__opts ) {
                |res, altered, opts|
                if res.start_transfer_time > TIME + @http.average_res_time
                    _log( res, altered, opts )
                end
            }
        }
    end

    def _log( res, altered, opts )

        elem = opts[:element]
        url  = res.effective_url
        print_ok( "In #{elem} var '#{altered}' " + ' ( ' + url + ' )' )

        injected = opts[:combo][altered] ? opts[:combo][altered] : '<n/a>'
        print_verbose( "Injected string:\t" + injected )
        print_debug( 'Request ID: ' + res.request.id.to_s )
        print_verbose( '---------' ) if only_positives?


        res = {
            :var          => altered,
            :url          => url,
            :injected     => injected,
            :id           => 'n/a',
            :regexp       => 'n/a',
            :regexp_match => 'n/a',
            :response     => res.body,
            :elem         => elem,
            :method       => res.request.method.to_s,
            :opts         => opts.dup,
            :verification => true,
            :headers      => {
                    :request    => res.request.headers,
                    :response   => res.headers,
                }
            }

            Arachni::Module::Manager.register_results(
                [ Vulnerability.new( res.merge( self.class.info ) ) ]
            )
    end

    def self.info
        {
            :name           => 'Blind (timing) SQL injection',
            :description    => %q{Blind SQL Injection module using timing attacks
                (if the remote server suddenly becomes unresponsive or your network
                connection suddenly chokes up this module will probably produce false positives).},
            :elements       => [
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE
            ],
            :author         => 'zapotek',
            :version        => '0.1',
            :references     => {
                'OWASP'      => 'http://www.owasp.org/index.php/Blind_SQL_Injection',
                'MITRE - CAPEC' => 'http://capec.mitre.org/data/definitions/7.html'
            },
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{Blind SQL Injection},
                :description => %q{SQL code can be injected into the web application
                    even though it may not be obvious due to suppression of error messages.},
                :cwe         => '89',
                :severity    => Vulnerability::Severity::HIGH,
                :cvssv2       => '9.0',
                :remedy_guidance    => %q{Suppression of error messages leads to
                    security through obscurity which is not a good practise.
                    The web application needs to enforce stronger validation
                    on user inputs.},
                :remedy_code => '',
                :metasploitable => 'unix/webapp/arachni_sqlmap'
            }

        }
    end

end
end
end
