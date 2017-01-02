=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Element::Capabilities
module Auditable

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module LineBuffered

    DEFAULT_LINE_BUFFER_SIZE = 1_000

    def line_buffered_audit( payloads, options = {}, &block )
        fail ArgumentError, 'Missing block.' if !block_given?

        options     = options.dup
        buffer_size = options[:buffer_size] || DEFAULT_LINE_BUFFER_SIZE

        print_debug_level_2 "About to audit #{buffer_size} lines at a time: #{audit_id}"

        buffers = {}

        options[:submit] ||= {}
        options[:submit][:on_body_lines] = proc do |lines, response|
            # In case of redirection or runtime scope changes.
            if !response.parsed_url.seed_in_host? && response.scope.out?
                print_debug_level_3 "Response out of scope for #{audit_id}: #{response.url}"
                print_debug_level_3 'Aborting...'
                next :abort
            end

            print_debug_level_3 "Got lines for: #{audit_id}"
            print_debug_level_4 lines

            request = response.request

            buffers[request.id] ||= {
                data:    '',
                counter: 0
            }
            buffer = buffers[request.id]

            buffer[:data]    << lines
            buffer[:counter] += lines.count( "\n" )

            print_debug_level_3 "Buffer is at: #{buffer[:counter]}/#{buffer_size}"
            next if buffer[:counter] < buffer_size

            print_debug_level_3 'Buffer full, setting response body.'
            print_debug_level_4 buffer[:data]

            response.body = buffer[:data]

            print_debug_level_3 "Calling: #{block}"

            # `false` means we're still buffering.
            r = block.call( response, request.performer, false )

            print_debug_level_3 "Block returned: #{r}"
            print_debug_level_3 'Emptying buffer.'

            # Create a new object, we don't want to mess with reference issues.
            buffer[:data]    = ''
            buffer[:counter] = 0

            r
        end

        audit( payloads, options ) do |response|
            print_debug_level_3 "Line buffering completed for: #{audit_id}"

            request = response.request
            buffer  = buffers[request.id]

            # The response body can include remnants from the HTTP line buffer
            # and our own buffer could have lines that didn't exceed the flush
            # threshold, hence we combine them
            if buffer && !buffer[:data].empty?
                b = response.body
                response.body = buffer[:data]
                response.body << b
            end

            print_debug_level_3 "Calling: #{block}"

            # `true` means we've read the entire response.
            block.call response, request.performer, true

            print_debug_level_3 'Deleted buffer.'
            buffers.delete( request.id )
        end
    end

end

end
end
end
