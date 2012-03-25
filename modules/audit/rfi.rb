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

module Arachni
module Modules

#
# Simple Remote File Inclusion tutorial module.
#
# It audits links, forms and cookies and will give you a good idea<br/>
# of how to write modules for Arachni.
#
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.1.4
#
# @see http://cwe.mitre.org/data/definitions/94.html
# @see http://projects.webappsec.org/Remote-File-Inclusion
# @see http://en.wikipedia.org/wiki/Remote_File_Inclusion
#
class RFI < Arachni::Module::Base # *always* extend Arachni::Module::Base

    #
    # OPTIONAL
    #
    # Gets called before any other method, right after initialization.
    # It provides you with a way to setup your module's data.
    #
    # It may be redundant but it's optional anyways...
    #
    def prepare
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
    def run
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
    def clean_up
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
                Issue::Element::COOKIE,
                Issue::Element::HEADER
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1.4',
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
                :tags        => [ 'remote', 'file', 'inclusion', 'injection', 'regexp' ],
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
