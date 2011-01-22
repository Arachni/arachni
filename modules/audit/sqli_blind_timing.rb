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
# Blind SQL Injection module using timing attacks.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://capec.mitre.org/data/definitions/7.html
# @see http://www.owasp.org/index.php/Blind_SQL_Injection
#
class BlindTimingSQLInjection < Arachni::Module::Base

    include Arachni::Module::Utilities

    TIME = 10000 # ms

    def initialize( page )
        super( page )
    end

    def prepare( )

        @@__injection_str ||= []

        if @@__injection_str.empty?
            read_file( 'payloads.txt' ) {
                |str|
                @@__injection_str << str.gsub( '__TIME__', ( TIME / 1000 ).to_s )
            }
        end

        @__opts = {
            :format  => [ Format::STRAIGHT ],
            :timeout => TIME + ( @http.average_res_time * 1000 ) - 500
        }

        @__logged = []
    end

    def run( )
        @found ||= false

        @@__injection_str.each {
            |str|
            audit( str, @__opts ) {
                |res, opts|

                next if @found

                # we have a timeout which probably means the attack succeeded
                if res.start_transfer_time == 0 && res.code == 0 && res.body.empty?
                    @found = true
                    # timing attacks require manual verification
                    opts[:verification] = true
                    log( opts, res )
                end
            }
        }
    end

    def self.info
        {
            :name           => 'Blind (timing) SQL injection',
            :description    => %q{Blind SQL Injection module using timing attacks
                (if the remote server suddenly becomes unresponsive or your network
                connection suddenly chokes up this module will probably produce false positives).},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE
            ],
            :author         => 'zapotek',
            :version        => '0.1.1',
            :references     => {
                'OWASP'      => 'http://www.owasp.org/index.php/Blind_SQL_Injection',
                'MITRE - CAPEC' => 'http://capec.mitre.org/data/definitions/7.html'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Blind SQL Injection (timing attack)},
                :description => %q{SQL code can be injected into the web application
                    even though it may not be obvious due to suppression of error messages.
                    (This issue was discovered using a timing attack; timing attacks
                    can result in false positives in cases where the server takes
                    an abnormally long time to respond.
                    Either case, these issues will require further investigation
                    even if they are false positives.)},
                :cwe         => '89',
                :severity    => Issue::Severity::HIGH,
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
