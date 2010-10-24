=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules
module Audit

#
# Simple Remote File Inclusion tutorial module.
#    
# It audits links, forms and cookies and will give you a good idea<br/>
# of how to write modules for Arachni.
#
#
# @author: Tasos "Zapotek" Laskos 
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.2
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
    # Initializes the module and the parent.
    #
    # @see Arachni::Module::Base
    # @see Page
    #
    # @param    [Page]    page    you can always expect this to be provided
    #                               by the system.
    #
    def initialize( page )
        # unless you want to do something freaky
        # *do not* ommit the following line
        super( page )

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
        #
        # You can use print debug for debugging.
        # Don't over-do ti though, debugging messages are supposed to
        # be helpful don't flood the output.
        #
        # Debugging output will only appear if "--debug" is enabled.
        #
        print_debug( 'In prepare()' )

        #
        # you can setup your module's environment as you wish
        # but it's good practice to prefix your attributes and methods
        # with 2 underscores ( @__foo_attr, __foo_meth() )
        #
        @__opts = {}
        @__opts[:regexp] = /<title>Google<\/title>/ixm
        
        # this is our RFI id signature, we'll look for it
        # in the HTTP response body
        #
        @__opts[:match]  = '<title>Google</title>'

        # inject this url to assess RFI
        @__injection_url = 'hTtP://google.com'

        
        #
        # the module can be made to detect XSS and many other kinds 
        # of attack just as easily if you adjust the above attributes
        # accordingly.
        #

        #
        # this array will hold the audit results to be registered
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
      
        print_debug(  'In run()' )
        
        #
        # You don't actually need to audit links,forms and cookies
        # individually and you don't need any of the user defined methods.
        #
        # You can simply do:
        #   audit( @__injection_url, @__opts )
        #
        # and be done with it.
        # 
        # All the stuff is here only to give you a feel for module writting.
        #
        
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
        print_debug( 'In clean_up()' )
    end

    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            :name           => 'SimpleRFI',
            :description    => %q{Simple Remote File Inclusion recon module},
            #
            # Arachni needs to know what elements the module plans to audit
            # before invoking it. If a page doesn't have any of those elements
            # there's no point putting the module in the thread queue.
            #
            # If you want the module to run no-matter what leave the array
            # empty or don't define it at all.
            # 
            :elements       => [
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE
            ],
            :author         => 'zapotek',
            :version        => '0.1.2',
            :references     => {
                'WASC'       => 'http://projects.webappsec.org/Remote-File-Inclusion',
                'Wikipedia'  => 'http://en.wikipedia.org/wiki/Remote_File_Inclusion'
            },
            :targets        => { 'Generic' => 'all' },
            
            :vulnerability   => {
                :name        => %q{Remote file inclusion},
                :description => %q{A remote file inclusion vulnerability exists.},
                :cwe         => '94',
                #
                # Severity can be:
                #
                # Vulnerability::Severity::HIGH
                # Vulnerability::Severity::MEDIUM
                # Vulnerability::Severity::LOW
                # Vulnerability::Severity::INFORMATIONAL
                #
                :severity    => Vulnerability::Severity::HIGH,
                :cvssv2      => '7.5',
                :remedy_guidance    => '',
                :remedy_code => '',
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
        # audit_links() is inherited from Arachni::Module::Base
        #
        # It helps you audit the current link's/url's variables.
        #
        # Look in Arachni::Module::Base#audit_links for documentation.
        #
        audit_links( @__injection_url, @__opts )
    end

    def __audit_forms(  )
        #
        # audit_forms() is inherited from Arachni::Module::Base
        #
        # It helps you audit all the form inputs of the current page.
        #
        # Look in Arachni::Module::Base#audit_forms for documentation.
        #        
         audit_forms( @__injection_url, @__opts )
    end

    def __audit_cookies( )
        #
        # audit_cookies() is inherited from Arachni::Module::Base
        #
        # It helps you audit the current page's cookies.
        #
        # Look in Arachni::Module::Base#audit_cookies for documentation.
        #
        audit_cookies( @__injection_url, @__opts )
    end

end
end
end
end
