=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

module Arachni

module Modules

#
# eval() recon module.
#
# It audits links, forms and cookies.
#
# It's designed to work with PHP, Perl, Python, Java, ASP and Ruby
# but still needs some more testing.
#
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: $Rev$
#
class Eval < Arachni::Module

    include Arachni::ModuleRegistrar
    include Arachni::UI::Output

    def initialize( page_data, structure )
        super( page_data, structure )

        # code to inject
        @__injection_strs = []
        
        # digits from a sha1 hash
        @__rand1 = '287630581954'
        @__rand2 = '4196403186331128'
        @__rand  =  (287630581954 + 4196403186331128).to_s
        
        @results = Hash.new
        @results['links'] = []
        @results['forms'] = []
        @results['cookies'] = []
            
    end

    def prepare( )
        @__injection_strs = [
            "echo " + @__rand1 + "+" + @__rand2 + ";",# PHP
            "print " + @__rand1 + "+" + @__rand2 + ";", # Perl
            "print " + @__rand1 + " + " + @__rand2, # Python
            "Response.Write\x28" +  @__rand1  + '+' + @__rand2 + "\x29", # ASP
            "puts " + @__rand1 + " + " + @__rand2 # Ruby
        ]
    end
    
    def run( )
        
        @__injection_strs.each {
            |str|
            
            enc_str = URI.encode( str )
            
            @results['forms'] |= 
                audit_forms( str, Regexp.new( @__rand ), @__rand )
                
            @results['links'] |= 
                audit_links( str, Regexp.new( @__rand ), @__rand )
                
            @results['cookies'] |=
                audit_cookies( str, Regexp.new( @__rand ), @__rand )
        }
        
        register_results( { 'Eval' => @results } )
    end

    
    def self.info
        {
            'Name'           => 'Eval',
            'Description'    => %q{eval() recon module. Tries to inject code
                into the web application.},
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
            'References'     =>
             [ 
             ],
            'Targets'        => { 'Generic' => 'all' }
        }
    end

end
end
end
