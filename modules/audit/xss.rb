=begin
                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules
module Audit

#
# XSS recon module.<br/>
# It audits links, forms and cookies.
#
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
# @see http://cwe.mitre.org/data/definitions/79.html    
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
#
class XSS < Arachni::Module::Base

    include Arachni::Module::Registrar
    include Arachni::UI::Output

    def initialize( page )
        super( page )

        @__injection_strs_file = []
        @results    = []
    end
    
    def prepare( )
        @__injection_strs_file = 'injection_strings.txt'
    end

    def run( )

        opts = { 
            :format => [ Format::APPEND | Format::NULL ]
        }
        #
        # it's better to save big arrays to a file
        # a big array is ugly, messy and can't be updated as easily
        #
        # but don't open the file yourself, use get_data_file( filename )
        # with a block and read each line
        #
        # the file must be under modules/<modtype>/<modname>/<filename>
        #
        get_data_file( @__injection_strs_file ) {
            |str|
            
            opts[:match]  =  str
            opts[:regexp] = Regexp.new( str )
            
            audit( str, opts )
        }
    end

    
    def self.info
        {
            :name           => 'XSS',
            :description    => %q{Cross-Site Scripting recon module},
            :elements       => [
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE,
                Vulnerability::Element::HEADER
            ],
            :author         => 'zapotek',
            :version        => '0.1',
            :references     => {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{Cross-Site Scripting (XSS)},
                :description => %q{Client-side code, like JavaScript, can
                    be injected into the web application.},
                :cwe         => '79',
                :severity    => Vulnerability::Severity::HIGH,
                :cvssv2       => '9.0',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

end
end
end
end
