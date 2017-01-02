=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Simple Remote File Inclusion (and tutorial) check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://cwe.mitre.org/data/definitions/94.html
# @see http://projects.webappsec.org/Remote-File-Inclusion
# @see http://en.wikipedia.org/wiki/Remote_File_Inclusion
class Arachni::Checks::Rfi < Arachni::Check::Base # *always* extend Arachni::Check::Base

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
            signatures: '705cd559b16e6946826207c2199bd890',
            submit:     {
                follow_location: false
            }
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
            description: %q{
Injects a remote URL in all available inputs and checks for relevant content in
the HTTP response body.
},

            # Arachni needs to know what elements the check plans to audit
            # before invoking it. If a page doesn't have any of those elements
            # there's no point in running the check.
            #
            # If you want the check to run no-matter what, leave the array
            # empty or don't define it at all.
            elements:    ELEMENTS_WITH_INPUTS - [Element::LinkTemplate],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:     '0.3.2',

            issue:       {
                name:        %q{Remote File Inclusion},
                description:     %q{
Web applications occasionally use parameter values to store the location of a file
which will later be required by the server.

An example of this is often seen in error pages, where the actual file path for
the error page is stored in a parameter value -- for example `example.com/error.php?page=404.php`.

A remote file inclusion occurs when the parameter value (ie. path to file being
called by the server) can be substituted with the address of remote resource --
for example: `yoursite.com/error.asp?page=http://anothersite.com/somethingBad.php`

In some cases, the server will process the fetched resource; therefore,
if the resource contains server-side code matching that of the framework being
used (ASP, PHP, JSP, etc.), it is probable that the resource will be executed
as if it were part of the web application.

Arachni discovered that it was possible to substitute a parameter value with an
external resource and have the server fetch it and include its contents in the response.
},
                references:  {
                    'WASC'      => 'http://projects.webappsec.org/Remote-File-Inclusion',
                    'Wikipedia' => 'http://en.wikipedia.org/wiki/Remote_File_Inclusion'
                },
                tags:       %w(remote file inclusion injection regexp),
                cwe:        94,

                # Severity can be:
                #
                # Severity::HIGH
                # Severity::MEDIUM
                # Severity::LOW
                # Severity::INFORMATIONAL
                severity:        Severity::HIGH,
                remedy_guidance: %q{
It is recommended that untrusted data is never used to form a file location to
be included.

To validate data, the application should ensure that the supplied value for a file
is permitted. This can be achieved by performing whitelisting on the parameter
value, by matching it against a list of permitted files. If the supplied value
does not match any value in the whitelist, then the server should redirect to a
standard error page.

In some scenarios, where dynamic content is being requested, it may not be possible
to perform validation against a list of trusted resources, therefore the list must
also become dynamic (updated as the files change), or perform filtering to remove
extraneous user input (such as semicolons, periods etc.) and only permit `a-z0-9`.

It is also advised that sensitive files are not stored within the web root and
that the user permissions enforced by the directory are correct.
}
            }
        }
    end

end
