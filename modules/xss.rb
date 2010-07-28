=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules

#
# XSS recon module.<br/>
# It audits links, forms and cookies.
#
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: $Rev$
#
# @see http://cwe.mitre.org/data/definitions/79.html    
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
#
class XSS < Arachni::Module::Base

    include Arachni::Module::Registrar
    include Arachni::UI::Output

    def initialize( page_data, structure )
        super( page_data, structure )

        @__injection_strs_file = []
        @results    = []
    end
    
    def prepare( )
        @__injection_strs_file = 'injection_strings.txt'
    end

    def run( )

        #
        # it's better to save big arrays to a file
        # a big array is ugly, messy and can't be updated as easily
        #
        # but don't open the file yourself, use get_data_file( filename )
        # with a block and read each line
        #
        # the file must be under modules/<modname>/<filename>
        #
        get_data_file( @__injection_strs_file ) {
            |str|

            audit_forms( str, Regexp.new( str ), str ).each {
                |res|
                @results << Vulnerability.new(
                    res.merge( { 'elem' => 'form' }.
                        merge( self.class.info )
                    )
                )
            }
            
            audit_links( str, Regexp.new( str ), str ).each {
                |res|
                @results << Vulnerability.new(
                    res.merge( { 'elem' => 'link' }.
                        merge( self.class.info )
                    )
                )
            }
            
            audit_cookies( str, Regexp.new( str ), str ).each {
                |res|
                @results << Vulnerability.new(
                    res.merge( { 'elem' => 'cookie' }.
                        merge( self.class.info )
                    )
                )
            }
            
        }
        
        register_results( @results )
    end

    
    def self.info
        {
            'Name'           => 'XSS',
            'Description'    => %q{Cross-Site Scripting recon module},
            'Elements'       => ['forms', 'links', 'cookies'],
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
            'References'     => {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            'Targets'        => { 'Generic' => 'all' },
                
            'Vulnerability'   => {
                'Name'        => %q{Cross-Site Scripting (XSS)},
                'Description' => %q{Client-side code, like JavaScript, can
                    be injected into the web application.},
                'CWE'         => '79',
                'Severity'    => 'High',
                'CVSSV2'       => '9.0',
                'Remedy_Guidance'    => '',
                'Remedy_Code' => '',
            }

        }
    end

end
end
end
