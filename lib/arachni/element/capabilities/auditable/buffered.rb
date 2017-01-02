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
module Buffered

    DEFAULT_BUFFER_SIZE = 15_000

    def buffered_audit( payloads, options = {}, &block )
        fail ArgumentError, 'Missing block.' if !block_given?

        options     = options.dup
        buffer_size = options[:buffer_size] || DEFAULT_BUFFER_SIZE

        print_debug_level_2 "About to audit at least #{buffer_size} bytes at a time: #{audit_id}"

        buffers = {}

        options[:submit] ||= {}
        options[:submit][:on_body] = proc do |chunk, response|
            # In case of redirection or runtime scope changes.
            if !response.parsed_url.seed_in_host? && response.scope.out?
                print_debug_level_3 "Response out of scope for #{audit_id}: #{response.url}"
                print_debug_level_3 'Aborting...'
                next :abort
            end

            print_debug_level_3 "Got data for: #{audit_id}"
            if debug?( 4 )
                print_debug_level_4 chunk
            end

            request = response.request

            buffers[request.id] ||= ''
            buffer = buffers[request.id]

            buffer << chunk

            print_debug_level_3 "Buffer is at: #{buffer.size}/#{buffer_size}"
            next if buffer.size < buffer_size

            print_debug_level_3 'Buffer full, setting response body.'
            print_debug_level_4 buffer
            response.body = buffer

            print_debug_level_3 "Calling: #{block}"
            r = block.call( response, request.performer, false )

            print_debug_level_3 "Block returned: #{r}"
            print_debug_level_3 'Emptying buffer.'

            # Create a new object, we don't want to mess with reference issues.
            buffers[request.id] = ''

            r
        end

        audit( payloads, options ) do |response|
            request = response.request
            buffer  = buffers[request.id]

            if !buffer.to_s.empty?
                print_debug_level_3 "There's more data in the buffer, setting response body."
                print_debug_level_3 buffer

                response.body = buffer
            else
                print_debug_level_3 "There's no buffer, leaving response body as is."
                print_debug_level_3 response.body
            end

            block.call response, request.performer, true

            buffers.delete( request.id )
        end
    end

end

end
end
end
