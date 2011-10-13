=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'set'
require Arachni::Options.instance.dir['lib'] + 'module/output'
require Arachni::Options.instance.dir['lib'] + 'module/utilities'
require Arachni::Options.instance.dir['lib'] + 'module/trainer'
require Arachni::Options.instance.dir['lib'] + 'module/auditor'

module Arachni
module Module


#
# Arachni's base module class<br/>
# To be extended by Arachni::Modules.
#
# Defines basic structure and provides utilities to modules.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
# @abstract
#
class Base

    # get output module
    include Output

    include Auditor

    #
    # Arachni::HTTP instance for the modules
    #
    # @return [Arachni::Module::HTTP]
    #
    attr_reader :http

    #
    # Arachni::Page instance
    #
    # @return [Page]
    #
    attr_reader :page

    #
    # Initializes the module attributes, HTTP client and {Trainer}
    #
    # @see Trainer
    # @see HTTP
    #
    # @param  [Page]  page
    #
    def initialize( page )

        @page  = page
        @http  = Arachni::HTTP.instance
        @http.trainer.set_page( @page )

        # update the cookies
        if( !@page.cookiejar.empty? )
            @http.update_cookies( @page.cookiejar )
        end

        #
        # This is slightly tricky...
        #
        # Each loaded module is instantiated for each page,
        # however modules share the elements of each page and access them
        # via the ElementsDB.
        #
        # Since the ElementDB is dynamically updated by the Trainer
        # during the audit, is should only be initialized *once*
        # for each page and not overwritten every single time a module is instantiated.
        #
        @@__last_url ||= ''
        if( @@__last_url != @page.url )
            @http.trainer.page = @page.dup
            @http.trainer.init_forms( @page.forms )
            @http.trainer.init_links( @page.links )
            @http.trainer.init_cookies( @page.cookies )
            @@__last_url = @page.url
        end
    end

    #
    # ABSTRACT - OPTIONAL
    #
    # It provides you with a way to setup your module's data and methods.
    #
    def prepare( )
    end

    #
    # ABSTRACT - REQUIRED
    #
    # This is used to deliver the module's payload whatever it may be.
    #
    def run( )
    end

    #
    # ABSTRACT - OPTIONAL
    #
    # This is called after run() has finished executing,
    #
    def clean_up( )
    end

    #
    # ABSTRACT - OPTIONAL
    #
    # Prevents auditting elements that have been previously
    # logged by any of the modules returned by this method.
    #
    # @return   [Array]     module names
    #
    def redundant
        # [ 'sqli', 'sqli_blind_rdiff' ]
        []
    end

    def framework
        @framework
    end

    #
    # ABSTRACT - REQUIRED
    #
    # Provides information about the module.
    # Don't take this lightly and don't ommit any of the info.
    #
    def self.info
        {
            :name           => 'Base module abstract class',
            :description    => %q{Provides an abstract class the modules should implement.},
            #
            # Arachni needs to know what elements the module plans to audit
            # before invoking it.
            # If a page doesn't have any of those elements
            # there's no point in instantiating the module.
            #
            # If you want the module to run no-matter what leave the array
            # empty.
            #
            # 'Elements'       => [
            #     Issue::Element::FORM,
            #     Issue::Element::LINK,
            #     Issue::Element::COOKIE,
            #     Issue::Element::HEADER
            # ],
            :elements       => [],
            :author         => 'zapotek',
            :version        => '0.1',
            :references     => {
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :description => %q{},
                :cwe         => '',
                #
                # Severity can be:
                #
                # Issue::Severity::HIGH
                # Issue::Severity::MEDIUM
                # Issue::Severity::LOW
                # Issue::Severity::INFORMATIONAL
                #
                :severity    => '',
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }
        }
    end

    def register_results( results )
        Arachni::Module::Manager.register_results( results )
    end

    def set_framework( framework )
        @framework = framework
    end

end
end
end
