=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# File inclusion audit module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
# @see http://cwe.mitre.org/data/definitions/98.html
# @see https://www.owasp.org/index.php/PHP_File_Inclusion
class Arachni::Modules::FileInclusion < Arachni::Module::Base

    def self.options
        @options ||= {
            format: [Format::STRAIGHT],
            regexp: {
                unix: [
                    /DOCUMENT_ROOT.*HTTP_USER_AGENT/,
                    /(root|mail):.+:\d+:\d+:.+:[0-9a-zA-Z\/]+/im
                ],
                windows: [
                    /\[boot loader\](.*)\[operating systems\]/im,
                    /\[fonts\](.*)\[extensions\]/im
                ],
                tomcat: [
                    /<web\-app/im
                ],

                # Generic PHP errors.
                php: [
                    /An error occurred in script/,
                    /Failed opening '.*?' for inclusion/,
                    /Failed opening required/,
                    /failed to open stream:.*/,
                    /<b>Warning<\/b>:\s+file/,
                    /<b>Warning<\/b>:\s+read_file/,
                    /<b>Warning<\/b>:\s+highlight_file/,
                    /<b>Warning<\/b>:\s+show_source/
                ],
                perl: [
                    /in .* at .* line d+?\./
                ]
            },

            # Add one more mutation (on the fly) which will include the extension
            # of the original value (if that value was a filename) after a null byte.
            each_mutation: proc do |mutation|
                m = mutation.dup

                # Figure out the extension of the default value, if it has one.
                ext = m.original[m.altered].to_s.split( '.' )
                ext = ext.size > 1 ? ext.last : nil

                # Null-terminate the injected value and append the ext.
                m.altered_value += "\x00.#{ext}"

                # Pass our new element back to be audited.
                m
            end
        }
    end

    def self.payloads
        @payloads ||= {
            unix:    [
                '/proc/self/environ',
                '/etc/passwd'
            ],
            windows: [
                '/boot.ini',
                '/windows/win.ini',
                '/winnt/win.ini'
            ].map { |p| [p, "c:#{p}", "#{p}#{'.'* 700}", p.gsub( '/', '\\' ) ] }.flatten,
            tomcat: [ '/WEB-INF/web.xml', '\WEB-INF\web.xml' ]
        }.inject({}) do |h, (platform, payloads)|
            h.merge platform => payloads.map { |p| [p, "file://#{p}" ] }.flatten
        end
    end

    def run
        audit self.class.payloads, self.class.options
    end

    def self.info
        {
            name:        'File Inclusion',
            description: %q{It injects paths of common files (/etc/passwd and boot.ini)
                and evaluates the existence of a file inclusion vulnerability
                based on the presence of relevant content or errors in the HTTP responses.},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.1',
            references:  {
                'OWASP' => 'https://www.owasp.org/index.php/PHP_File_Inclusion'
            },
            targets:     %w(Unix Windows Tomcat PHP Perl),

            issue:       {
                name:            %q{File Inclusion},
                description:     %q{The web application enforces improper limitation
                    of a pathname.},
                tags:            %w(file inclusion error injection regexp),
                cwe:             '98',
                severity:        Severity::HIGH,
                remedy_guidance: %q{User inputs must be validated and filtered
                    before being used as a part of a filesystem path.}
            }

        }
    end

end
