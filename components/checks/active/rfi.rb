=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Simple Remote File Inclusion (and tutorial) check.
#
# It audits links, forms and cookies and will give you a good idea
# of how to write checks for Arachni.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2
#
# @see http://cwe.mitre.org/data/definitions/94.html
# @see http://projects.webappsec.org/Remote-File-Inclusion
# @see http://en.wikipedia.org/wiki/Remote_File_Inclusion
#
class Arachni::Checks::RFI < Arachni::Check::Base # *always* extend Arachni::Check::Base

    #
    # OPTIONAL
    #
    # Gets called before any other method, right after initialization.
    # It provides you with a way to setup your check's dynamic data.
    #
    def prepare
        #
        # You can use #print_debug for debugging.
        # Don't over-do it though, debugging messages are supposed to be helpful
        # so don't flood the output.
        #
        # Debugging output will only appear if "--debug" is enabled.
        #
        print_debug 'In #prepare'
    end

    #
    # To prepare static data use class methods with lazy loaded class variables.
    #
    # Each check will be run multiple times so there's no sense in constantly
    # initializing the same stuff over and over again and every little helps.
    #

    #
    # It's Framework convention to name the method which contains the strings
    # to be injected {.payloads}.
    #
    def self.payloads
        @payloads ||= [
            'hTtP://tests.arachni-scanner.com/rfi.md5.txt',
            'http://tests.arachni-scanner.com/rfi.md5.txt',
            'tests.arachni-scanner.com/rfi.md5.txt'
        ]
    end

    #
    # It's Framework convention to name the method which contains the audit
    # options {.options}.
    #
    def self.options
        @options ||= {
            substring:       '705cd559b16e6946826207c2199bd890',
            follow_location: false
        }
    end

    #
    # REQUIRED
    #
    # This is used to deliver the check's payload, whatever it may be.
    #
    def run
        print_debug 'In #run'
        audit self.class.payloads, self.class.options
    end

    #
    # OPTIONAL
    #
    # This is called after {#run} has finished executing and it allows you
    # to clean up after yourself.
    #
    def clean_up
        print_debug 'In #clean_up'
    end

    #
    # REQUIRED
    #
    # Do not omit any of the info.
    #
    def self.info
        {
            name:        'Remote File Inclusion',
            description: %q{It injects a remote URL in all available
                inputs and checks for relevant content in the HTTP response body.},
            #
            # Arachni needs to know what elements the check plans to audit
            # before invoking it. If a page doesn't have any of those elements
            # there's no point in running the check.
            #
            # If you want the check to run no-matter what, leave the array
            # empty or don't define it at all.
            #
            elements:    [ Element::Form, Element::Link, Element::Cookie, Element::Header ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2.1',
            references:  {
                'WASC'      => 'http://projects.webappsec.org/Remote-File-Inclusion',
                'Wikipedia' => 'http://en.wikipedia.org/wiki/Remote_File_Inclusion'
            },
            targets:     %w(Generic),

            issue:       {
                name:        %q{Remote File Inclusion},
                description: %q{The web application can be forced to include
    3rd party remote content which can often lead to arbitrary code
    execution, amongst other attacks.},
                tags:       %w(remote file inclusion injection regexp),
                cwe:        '94',
                #
                # Severity can be:
                #
                # Severity::HIGH
                # Severity::MEDIUM
                # Severity::LOW
                # Severity::INFORMATIONAL
                #
                severity:        Severity::HIGH,
                cvssv2:          '7.5',
                remedy_guidance: %q{Enforce strict validation and filtering
                    on user inputs.},
                remedy_code:     '',
                metasploitable:  'unix/webapp/arachni_php_include'
            }

        }
    end

end
