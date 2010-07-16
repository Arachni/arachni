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

    # register us with the system
    include Arachni::ModuleRegistrar
    # get output interface
    include Arachni::UI::Output

    def initialize( page_data, structure )
        super( page_data, structure )

        # code to inject
        @__injection_strs = []
        
        # digits from a sha1 hash
        # the codes in @__injection_strs with tell the web app
        # to sum them and echo them
        @__rand1 = '287630581954'
        @__rand2 = '4196403186331128'
        
        # the sum of the 2 numbers as a string
        @__rand  =  (287630581954 + 4196403186331128).to_s
        
        # our results hash
        @results = Hash.new
        @results['links'] = []
        @results['forms'] = []
        @results['cookies'] = []
            
    end

    def prepare( )
        
        # code to be injected to the webapp
        @__injection_strs = [
            "echo " + @__rand1 + "+" + @__rand2 + ";", # PHP
            "print " + @__rand1 + "+" + @__rand2 + ";", # Perl
            "print " + @__rand1 + " + " + @__rand2, # Python
            "Response.Write\x28" +  @__rand1  + '+' + @__rand2 + "\x29", # ASP
            "puts " + @__rand1 + " + " + @__rand2 # Ruby
        ]
    end
    
    def run( )
        
        # iterate through the injection codes
        @__injection_strs.each {
            |str|
            
            # URL encode the code
            enc_str = URI.encode( str )
            
            # audit forms and add the results to the results array
            @results['forms'] |= 
                audit_forms( str, Regexp.new( @__rand ), @__rand )
            
            # audit links and add the results to the results array    
            @results['links'] |= 
                audit_links( str, Regexp.new( @__rand ), @__rand )
            
            # audit cookies and add the results to the results array
            @results['cookies'] |=
                audit_cookies( str, Regexp.new( @__rand ), @__rand )
        }
        
        # register our results with the system
        register_results( { 'Eval' => @results } )
    end

    
    def self.info
        {
            'Name'           => 'Eval',
            'Description'    => %q{eval() recon module. Tries to inject code
                into the web application.},
            'Methods'        => ['get', 'post', 'cookie'],
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
            'References'     => {
                'PHP'    => 'http://php.net/manual/en/function.eval.php',
                'Perl'   => 'http://perldoc.perl.org/functions/eval.html',
                'Python' => 'http://docs.python.org/py3k/library/functions.html#eval',
                'ASP'    => 'http://www.aspdev.org/asp/asp-eval-execute/',
                'Ruby'   => 'http://en.wikipedia.org/wiki/Eval#Ruby'
             },
            'Targets'        => { 'Generic' => 'all' }
        }
    end

end
end
end
