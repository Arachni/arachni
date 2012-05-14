=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

require 'set'
require Arachni::Options.instance.dir['lib'] + 'module/output'
require Arachni::Options.instance.dir['lib'] + 'module/utilities'
require Arachni::Options.instance.dir['lib'] + 'module/trainer'
require Arachni::Options.instance.dir['lib'] + 'module/auditor'

module Arachni
module Module


#
# Base module class to be extended by all modules.
#
# Defines basic structure and provides utilities to modules.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
#
class Base

    # get output module
    include Output
    include Auditor

    #
    # @return [Arachni::Module::HTTP]
    #
    attr_reader :http

    #
    # @return [Page]
    #
    attr_reader :page

    #
    # @return [Arachni::Framework]
    #
    attr_reader :framework

    #
    # Initializes the module attributes, HTTP client and {Trainer}
    #
    # @see Trainer
    # @see HTTP
    #
    # @param  [Page]  page
    # @param  [Arachni::Framework]  framework
    #
    def initialize( page, framework = nil )
        @page  = page
        @framework  = framework

        @http  = Arachni::HTTP.instance
        @http.trainer.page = @page

        # update the cookies
        @http.update_cookies( @page.cookiejar ) if( !@page.cookiejar.empty? )

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
        if @@__last_url != @page.url
            @http.trainer.init_from_page!( @page )
            @@__last_url = @page.url
        end
    end

    #
    # OPTIONAL
    #
    # It provides you with a way to setup your module's data and methods.
    #
    # @abstract
    #
    def prepare
    end

    #
    # REQUIRED
    #
    # This is used to deliver the module's payload whatever it may be.
    #
    # @abstract
    #
    def run
    end

    #
    # OPTIONAL
    #
    # This is called after run() has finished executing,
    #
    # @abstract
    #
    def clean_up
    end

    #
    # Provides access to the plugin manager
    #
    # You can use it to gain access to the instances of running plugins like so:
    #
    #    p plugins.get( 'profiler' )
    #    # => #<Thread:0x000000025b2ff0 sleep>
    #
    #    p plugins.get( 'profiler' )[:instance]
    #    # => #<Arachni::Plugins::Profiler>
    #
    # @return   [Arachni::PluginManager]
    #
    def plugins
        framework.plugins if framework
    end

    #
    # REQUIRED
    #
    # Provides information about the module.
    # Don't take this lightly and don't ommit any of the info.
    #
    # @abstract
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

    def set_framework( framework )
        @framework = framework
    end

end
end
end
