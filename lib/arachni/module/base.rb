=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

module Arachni

lib = Arachni::Options.dir['lib']
require lib + 'module/output'
require lib + 'module/utilities'
require lib + 'module/auditor'

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
    # I hate keep typing this all the time...
    include Arachni

    include Utilities
    extend  Utilities

    include Auditor

    #
    # Initializes the module attributes and {Arachni::HTTP}.
    #
    # @param  [Page]  page
    # @param  [Arachni::Framework]  framework
    #
    def initialize( page, framework )
        http.update_cookies( page.cookiejar )

        @page       = page
        @framework  = framework
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

    def session
        framework.session if framework
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
            name:        'Base module abstract class',
            description: %q{Provides an abstract class the modules should implement.},
            #
            # Arachni needs to know what elements the module plans to audit
            # before invoking it.
            # If a page doesn't have any of those elements
            # there's no point in instantiating the module.
            #
            # If you want the module to run no-matter what, leave the array
            # empty.
            #
            # elements: [
            #     Element::FORM,
            #     Element::LINK,
            #     Element::COOKIE,
            #     Element::HEADER
            # ],
            elements:    [],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            references:  {
                'Title' => 'http://ref.url'
            },
            targets:     %W(Generic),
            issue:       {
                name:           %q{Serious issue},
                description:    %q{This issue is a serious issue and you
                    should consider it seriously},
                # CWE ID number
                cwe:            '',
                #
                # Severity can be:
                #
                # Severity::HIGH
                # Severity::MEDIUM
                # Severity::LOW
                # Severity::INFORMATIONAL
                #
                severity:        Severity::HIGH,
                cvssv2:          '', # CVSSV2 score
                remedy_guidance: %q{Paint it blue and throw it in the sea.},
                remedy_code:     %q{sudo rm -rf /}
            }
        }
    end

    #
    # Schedules self to be run *after* the specified modules and prevents
    # auditing elements that have been previously logged by any of these modules.
    #
    # @return   [Array]     module names
    #
    def self.prefer( *args )
        @preferred = args.flatten.compact
    end

    #
    # @return   [Array]     names of modules which should be preferred over this one
    #
    # @see #prefer
    #
    def self.preferred
        @preferred ||= []
    end
    def preferred
        self.class.preferred
    end


end
end
end
