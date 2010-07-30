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
# Simple Remote File Inclusion tutorial module.
#    
# It audits links, forms and cookies and will give you a good idea<br/>
# of how to write modules for Arachni.
#
#
# @author: Anastasios "Zapotek" Laskos 
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: $Rev$
#
# @see http://cwe.mitre.org/data/definitions/94.html    
# @see http://projects.webappsec.org/Remote-File-Inclusion
# @see http://en.wikipedia.org/wiki/Remote_File_Inclusion
#
class SimpleRFI < Arachni::Module::Base # *always* extend Arachni::Module::Base

    #
    # Arachni::Module::HTTP instance
    #
    # You don't really need to declare this,
    # you inherit it from Arachni::Module
    #
    # It's an initialized object of the Arachni::Module::HTTP instance
    # class configured with proxy, authentication, SSL settings etc.
    #
    # Look at Arachni::Module::HTTP instance doc to see what you get.
    #
    # If you need direct access to the Net::HTTP session you can get
    # it from @http.session
    #
    # @return [Arachni::Module::HTTP]
    #
    attr_reader :http

    #
    # REQUIRED
    #
    # Register us with the system.
    # If you ommit this the system won't be able to see you.
    #
    include Arachni::Module::Registrar
    
    #
    # REQUIRED
    #
    # Include the output class for the current user interface.
    # if you ommit this you won't be able to talk to the user.
    #
    include Arachni::UI::Output

    #
    # REQUIRED
    #
    # Initialize the module and the parent.
    #
    def initialize( page_data, structure )
        # unless you want to do something freaky
        # *do not* ommit the following line
        super( page_data, structure )

        # init your stuff here
    end

    #
    # OPTIONAL
    #
    # Gets called before any other method, right after initialization.
    # It provides you with a way to setup your module's data.
    #
    # It may be redundant but it's optional anyways...
    #
    def prepare( )
        print_debug( 'In SimpleRFI.prepare()' )

        #
        # you can setup your modules environment as you wish
        # but it's good practice to prefix your attributes and methods
        # with 2 underscores ( @__foo_attr, __foo_meth() )
        #

        # this is our RFI id signature, we'll look for it
        # in the HTTP response body
        #
            @__rfi_id_regex = /<title>Google<\/title>/ixm
            @__rfi_id = '<title>Google</title>'
#        @__rfi_id_regex = /d3612e6ae8c17e46fa8592c8bdb8f2f3/ixm
#        @__rfi_id = 'd3612e6ae8c17e46fa8592c8bdb8f2f3'

        # inject this url to asses RFI
            @__injection_url = 'hTtP://google.com'
#        @__injection_url = 'http://localhost/zapotek/fis/file.txt'

        #
        # the module can be made to detect XSS and many other kinds 
        # of attack just as easily if you adjust the above attributes
        # accordingly.
        #

        #
        # this hash will keep the audit results to be registered
        # with the system, using:
        #
        # register_results( @results )
        #
        # Should be an array of Vulnerability objects
        #
        @results = []
    end

    #
    # REQUIRED
    #
    # This is used to deliver the module's payload whatever it may be.
    #
    def run( )
        print_debug(  'In SimpleRFI.run()' )

        __audit_links()
        __audit_forms( )
        __audit_cookies()
    end

    #
    # OPTIONAL
    #
    # This is called after run() has finished executing,
    # it allows you to clean up after yourself.
    #
    # May also be redundant but, once again, it's optional
    #
    def clean_up( )
        print_debug( 'In SimpleRFI.clean_up()' )

        #
        # REQUIRED
        #
        # Register our results with the ModuleRegistry
        # via the ModuleRegistrar.
        #
        # Doesn't *have* to be in clean_up().
        #
        register_results( @results )
    end

    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            'Name'           => 'SimpleRFI',
            'Description'    => %q{Simple Remote File Inclusion recon module},
            #
            # Arachni needs to know what elements the module plans to audit
            # before invoking it. If a page doesn't have any of those elements
            # there's no point putting the module in the thread queue.
            #
            # If you want the module to run no-matter what leave the array
            # empty or don't define it at all.
            # 
            'Elements'       => ['forms', 'links', 'cookies'],
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
            'References'     => {
                'WASC'       => 'http://projects.webappsec.org/Remote-File-Inclusion',
                'Wikipedia'  => 'http://en.wikipedia.org/wiki/Remote_File_Inclusion'
            },
            'Targets'        => { 'PHP' => 'all' },
            
            'Vulnerability'   => {
                'Name'        => %q{Remote file inclusion},
                'Description' => %q{A remote file inclusion vulnerability exists.},
                'CWE'         => '94',
                #
                # Severity can be:
                #
                # Vulnerability::Severity::HIGH
                # Vulnerability::Severity::MEDIUM
                # Vulnerability::Severity::LOW
                # Vulnerability::Severity::INFORMATIONAL
                #
                'Severity'    => Vulnerability::Severity::HIGH,
                'CVSSV2'       => '7.5',
                'Remedy_Guidance'    => '',
                'Remedy_Code' => '',
            }
            
        }
    end
    
    #
    # OPTIONAL
    #
    # In case you depend on other modules you can return an array
    # of their names (not their class names, the module names as they
    # appear by the "-l" CLI argument) and they will be loaded for you.
    #
    # This is also great for creating audit/discovery/whatever profiles.
    #
    def self.deps
        # example:
        # ['eval', 'sqli']
        []
    end

    #
    # The following are our own helper methods.
    # It's good practice to prefix them with 2 undescores ( __foo() ).
    #
    # It's also good practice to declare them as private
    # unless you have modules that need to interact with each other.
    #
    private

    def __audit_links( )
        #
        # audit_links() is inherited from Arachni::Module
        #
        # It helps you audit the current link's/url's variables.
        #
        # Look in Arachni::Module#audit_links for documentation.
        #
        audit_links( @__injection_url, @__rfi_id_regex, @__rfi_id ).each {
            |res|
            # create a vulnerability and add it to the results array
            @results << Vulnerability.new(
                
                # the returned hash of audit methods conviniently
                # holds part of the hash that is expected by Vulnerability.new()
                #
                # to complete the hash we merge it with the module's
                # class method info(), with the added field of
                # 'elem' which specifies the HTML element that is vulnerable.
                res.merge( { 'elem' => 'link' }.
                    merge( self.class.info )
                )
            )
        }
    end

    def __audit_forms(  )
        #
        # audit_forms() is inherited from Arachni::Module
        #
        # It helps you audit all the form inputs of the current page.
        #
        # Look in Arachni::Module#audit_forms for documentation.
        #        
         audit_forms( @__injection_url, @__rfi_id_regex, @__rfi_id ).each {
             |res|
             @results << Vulnerability.new(

                 # the returned hash of audit methods conviniently
                 # holds part of the hash that is expected by Vulnerability.new()
                 #
                 # to complete the hash we merge it with the module's
                 # class method info(), with the added field of
                 # 'elem' which specifies the HTML element that is vulnerable.
                 res.merge( { 'elem' => 'form' }.
                     merge( self.class.info )
                 )
             )
         }
    end

    def __audit_cookies( )
        #
        # audit_cookies() is inherited from Arachni::Module
        #
        # It helps you audit the current page's cookies.
        #
        # Look in Arachni::Module#audit_cookies for documentation.
        #
        audit_cookies( @__injection_url, @__rfi_id_regex, @__rfi_id ).each {
            |res|
            
            # the returned hash of audit methods conviniently
            # holds part of the hash that is expected by Vulnerability.new()
            #
            # to complete the hash we merge it with the module's
            # class method info(), with the added field of
            # 'elem' which specifies the HTML element that is vulnerable.
            @results << Vulnerability.new(
                res.merge( { 'elem' => 'cookie' }.
                    merge( self.class.info )
                )
            )
        }
    end

end
end
end
