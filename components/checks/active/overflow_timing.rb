=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Tries to inject overflow, if work, will cause crash process and timeout response
#
#
# @author Lionel PRAT <lionel.prat9@gmail.com>
#
# @version 0.0.1
#
class Arachni::Checks::OverflowTiming < Arachni::Check::Base

    prefer :overflow_injection

    def self.payloads
        @payloads ||= [ '\0' * 2056, "A" * 2056, '%ff' * 2056, "\n" * 2056 ]
    end

    def run
        audit_timeout( self.class.payloads, format: [Format::STRAIGHT], timeout: 4000 )
    end

    def self.info
        {
            name:        'Overflow injection (timing)',
            description: %q{
Injects overflow whether or not the overflow was successful using
a time delay.
},
            elements:    ELEMENTS_WITH_INPUTS,
            author:      'Lionel PRAT <lionel.prat9@gmail.com>',
            version:     '0.0.1',
            
            issue:       {
                name:            %q{Code overflow (timing attack)},
                description:     %q{
Overflow occurs when the server takes untrusted code (ie. from the client)
and executes it with memory limit.

},
                tags:            %w(overflow injection timing blind),
                cwe:             119,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
It is recommended that untrusted input is never processed as server-side code.

To validate input, the application should ensure that the supplied value contains
only the data that are required to perform the relevant action.

For example, where a username is required, then no non-alpha characters should not
be accepted and verify size max.
}
            }
        }
    end

end
