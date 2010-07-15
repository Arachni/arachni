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
# Simple Remote File Inclusion tutorial module.
# It audits links, forms and cookies and will give you a good idea
# of how to write modules for Arachni.
#
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: $Rev$
#
class SimpleRFI < Arachni::Module # *always* extend Arachni::Module

    #
    # Arachni::HTTP instance
    #
    # You don't really need to declare this,
    # you inherit it from Arachni::Module
    #
    # It's an initialized object of the Arachni::HTTP class configured
    # with proxy, authentication, SSL settings etc.
    #
    # Look at Arachni::HTTP doc to see what you get.
    #
    # If you need direct access to the Net::HTTP session you can get
    # it from @http.session
    #
    # @return [Arachni::HTTP]
    #
    attr_reader :http

    #
    # REQUIRED
    #
    # Register us with the system.
    # If you ommit this the system won't be able to see you.
    #
    include Arachni::ModuleRegistrar
    
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
        # register_results( { 'SimpleRFI' => @results } )
        #
        # the structure of the results must be preserved
        #
        @results = Hash.new
        @results['links'] = []
        @results['forms'] = []
        @results['cookies'] = []
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
        register_results( { 'SimpleRFI' => @results } )
    end

    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    # If you don't have something to say here just leave the values empty.
    #
    def self.info
        {
            'Name'           => 'SimpleRFI',
            'Description'    => %q{Simple Remote File Inclusion recon module},
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
            'References'     => {
                'WASC'      => 'http://projects.webappsec.org/Remote-File-Inclusion',
                'Wikipedia' => 'http://en.wikipedia.org/wiki/Remote_File_Inclusion'
            },
            'Targets'        => { 'PHP' => 'all' }
        }
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
        res = audit_links( @__injection_url, @__rfi_id_regex, @__rfi_id )
        @results['links'] = res if res && res.size > 0
    end

    def __audit_forms(  )
        #
        # audit_forms() is inherited from Arachni::Module
        #
        # It helps you audit all the form inputs of the current page.
        #
        # Look in Arachni::Module#audit_forms for documentation.
        #        
        res = audit_forms( @__injection_url, @__rfi_id_regex, @__rfi_id )
        @results['forms'] = res if res && res.size > 0
    end

    def __audit_cookies( )
        #
        # audit_cookies() is inherited from Arachni::Module
        #
        # It helps you audit the current page's cookies.
        #
        # Look in Arachni::Module#audit_cookies for documentation.
        #
        res = audit_cookies( @__injection_url, @__rfi_id_regex, @__rfi_id )
        @results['cookies'] = res if res && res.size > 0
    end

end
end
end
