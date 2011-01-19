=begin
  $Id$

                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

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
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.3
#
# @see http://cwe.mitre.org/data/definitions/94.html
# @see http://projects.webappsec.org/Remote-File-Inclusion
# @see http://en.wikipedia.org/wiki/Remote_File_Inclusion
#
class RFI < Arachni::Module::Base # *always* extend Arachni::Module::Base

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
        # You can use print_debug() for debugging.
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
        @__opts[:substring] = '705cd559b16e6946826207c2199bd890'

        # inject this url to assess RFI
        @__injection_url = 'http://zapotek.github.com/arachni/rfi.md5.txt'


        #
        # the module can be made to detect XSS and many other kinds
        # of attack just as easily if you adjust the above attributes
        # accordingly.
        #

    end

    #
    # REQUIRED
    #
    # This is used to deliver the module's payload whatever it may be.
    #
    def run( )
        print_debug(  'In run()' )

        audit( @__injection_url, @__opts )
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
            :name           => 'Remote File Inclusion',
            :description    => %q{It injects a remote URL in all available
                inputs and checks for relevant content in the HTTP response body.},
            #
            # Arachni needs to know what elements the module plans to audit
            # before invoking it. If a page doesn't have any of those elements
            # there's no point putting the module in the thread queue.
            #
            # If you want the module to run no-matter what leave the array
            # empty or don't define it at all.
            #
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE
            ],
            :author         => 'zapotek',
            :version        => '0.1.3',
            :references     => {
                'WASC'       => 'http://projects.webappsec.org/Remote-File-Inclusion',
                'Wikipedia'  => 'http://en.wikipedia.org/wiki/Remote_File_Inclusion'
            },
            :targets        => { 'Generic' => 'all' },

            :issue   => {
                :name        => %q{Remote file inclusion},
                :description => %q{The web application can be forced to include
                    3rd party remote content which can often lead to arbitrary code
                    execution, amongst other attacks.},
                :cwe         => '94',
                #
                # Severity can be:
                #
                # Issue::Severity::HIGH
                # Issue::Severity::MEDIUM
                # Issue::Severity::LOW
                # Issue::Severity::INFORMATIONAL
                #
                :severity    => Issue::Severity::HIGH,
                :cvssv2      => '7.5',
                :remedy_guidance    => %q{Enforce strict validation and filtering
                    on user inputs.},
                :remedy_code => '',
                :metasploitable	=> 'unix/webapp/arachni_php_include'
            }

        }
    end

end
end
end
