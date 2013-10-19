=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

module Element::Capabilities

module Auditable

# Performs boolean, fault injection and behavioral analysis (using the rDiff algorithm)
# in order to determine whether the web application is responding to the injected data and how.
#
# If the behavior can be manipulated by the injected data in ways that it's not supposed to
# (like when evaluating injected code) then the element is deemed vulnerable.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module RDiff

    RDIFF_OPTIONS =  {
        # Append our seeds to the default values.
        format:         [Mutable::Format::STRAIGHT],

        # Amount of refinement operations to remove context-irrelevant dynamic
        # content -- like banners etc.
        precision:      2,

        # Ratio of allowed difference between the compared (refined) response bodies.
        # `0.0` means the bodies should be identical to be considered the same.
        ratio:          0.18,

        # Override global fuzzing settings and only use the default method of the
        # element under audit.
        respect_method: true,

        # Don't generate or submit any mutations with default or sample inputs.
        skip_orig:      true,

        # Allow redundant audits, we need multiple ones for noise-reduction.
        redundant:      true,

        # Don't let #audit print output, we'll handle that ourselves.
        silent:         true,

        # Default value for a forceful 'false' response.
        false:          '-1'
    }

    #
    # Performs differential analysis and logs an issue should there be one.
    #
    #     opts = {
    #         false: 'false resource id',
    #         pairs: [
    #               { 'true expression' => 'false expression' }
    #         ]
    #     }
    #
    #     element.rdiff_analysis( opts )
    #
    # Here's how it goes:
    #
    # * let `control` be the response of the injection of 'false resource id'
    # * let `true_response` be the response of the injection of 'true expression'
    # * let `false_response` be the response of the injection of 'false expression'
    # * let `control_verification` be a fresh control
    #
    # A vulnerability is logged if:
    #
    #     control == control_verification && control == false_response AND
    #       true_response.code == 200 AND false_response != true_response
    #
    # The `bool` response is also checked in order to determine if it's a custom
    # 404, if it is then it'll be skipped.
    #
    # If a block has been provided analysis and logging will be delegated to it.
    #
    # @param    [Hash]  opts
    # @option   opts    [Integer]       :format
    #   As seen in {Arachni::Element::Capabilities::Mutable::Format}.
    # @option   opts    [Integer]       :precision
    #   Amount of {String#rdiff refinement} iterations to perform.
    # @option   opts    [Array<Hash>] :pairs
    #   Pair of strings that should yield different results when interpreted.
    #   Keys should be the `true` expressions.
    # @option   opts    [String]       :false
    #   A string which would illicit a 'false' response but without any code.
    # @param    [Block]     block
    #   To be used for custom analysis of gathered data.
    #
    # @return   [Bool]
    #   `true` if the audit was scheduled successfully, `false` otherwise (like
    #   if the resource is out of scope or already audited).
    #
    def rdiff_analysis( opts = {}, &block )
        if skip_path? self.action
            print_debug "Element's action matches skip rule, bailing out."
            return false
        end

        opts = self.class::MUTATION_OPTIONS.merge( RDIFF_OPTIONS.merge( opts ) )

        #return false if auditable.empty?
        #
        #filled_in_inputs = Arachni::Module::KeyFiller.fill( auditable, '' )
        #
        ## Don't continue if there's a missing value.
        #filled_in_inputs.values.each { |val| return if val.to_s.empty? }

        return false if audited? audit_id
        audited audit_id

        # Holds all the data from the probes.
        responses = {
            controls: {}
        }

        corrupted = false

        received_requests = 0
        opts[:precision].times do

            # Get the default response.
            audit( opts[:false], opts ) do |res, _, elem|
                next if corrupted

                if res.body.to_s.empty?
                    print_bad 'Server returned empty response body, aborting analysis.'
                    corrupted = true
                    next
                end

                received_requests += 1

                if responses[:controls][elem.altered]
                    print_status "Got default/control response for #{elem.type} " +
                        "variable '#{elem.altered}' with action '#{elem.action}'."
                end

                # Remove context-irrelevant dynamic content like banners and such.
                responses[:controls][elem.altered] =
                    responses[:controls][elem.altered] ?
                        responses[:controls][elem.altered].rdiff( res.body ) : res.body

                next if received_requests != opts[:precision]
                rdiff_fire_true_probes( opts, responses, &block )
            end
        end

        true
    end

    private

    def rdiff_fire_true_probes( opts, responses, &block )
        received_responses = 0

        opts[:pairs].each do |pair|
            responses[pair] ||= {}
            true_expr = pair.to_a.first[0]

            opts[:precision].times do
                true_mutations     = mutations( true_expr, opts )
                expected_responses = true_mutations.size * opts[:precision] * opts[:pairs].size

                true_mutations.each do |elem|

                    # Submit the mutation and store the response.
                    elem.submit( opts ) do |res|
                        responses[pair][elem.altered] ||= {}

                        next if responses[pair][elem.altered][:corrupted]
                        if res.body.to_s.empty?
                            print_status 'Server returned empty response body,' <<
                                " aborting analysis for #{elem.type} variable " <<
                                "'#{elem.altered}' with action '#{elem.action}'."
                            responses[pair][elem.altered][:corrupted] = true
                            next
                        end

                        received_responses += 1

                        if responses[pair][elem.altered][:true]
                            elem.print_status "Gathering data for #{elem.type} " <<
                                "variable '#{elem.altered}' with action '#{elem.action}'" <<
                                " -- Got true  response: #{true_expr}"
                        end

                        responses[pair][elem.altered][:mutation] = elem

                        # Keep the latest response for the {Arachni::Issue}.
                        responses[pair][elem.altered][:response]        = res
                        responses[pair][elem.altered][:injected_string] = true_expr

                        responses[pair][elem.altered][:true] ||= res.body.dup
                        # Remove context-irrelevant dynamic content like banners
                        # and such from the error page.
                        responses[pair][elem.altered][:true] =
                            responses[pair][elem.altered][:true].rdiff( res.body.dup )

                        next if expected_responses != received_responses
                        rdiff_fire_false_probes( opts, responses, &block )
                    end
                end
            end
        end
    end

    def rdiff_fire_false_probes( opts, responses, &block )
        received_responses = 0

        opts[:pairs].each do |pair|
            false_expr = pair.to_a.first[1]

            opts[:precision].times do
                false_mutations    = mutations( false_expr, opts )
                expected_responses = false_mutations.size * opts[:precision] * opts[:pairs].size

                false_mutations.each do |elem|

                    # Submit the mutation and store the response.
                    elem.submit( opts ) do |res|

                        next if responses[pair][elem.altered][:corrupted]
                        if res.body.to_s.empty?
                            print_status 'Server returned empty response body,' <<
                                " aborting analysis for #{elem.type} variable " <<
                                "'#{elem.altered}' with action '#{elem.action}'."
                            responses[pair][elem.altered][:corrupted] = true
                            next
                        end

                        received_responses += 1

                        if responses[pair][elem.altered][:false]
                            elem.print_status "Gathering data for #{elem.type} " <<
                                "variable '#{elem.altered}' with action '#{elem.action}'" <<
                                " -- Got false response: #{false_expr}"
                        end

                        responses[pair][elem.altered][:false] ||= res.body.dup
                        # Remove context-irrelevant dynamic content like banners
                        # and such from the error page.
                        responses[pair][elem.altered][:false] =
                            responses[pair][elem.altered][:false].rdiff( res.body.dup )

                        next if expected_responses != received_responses
                        rdiff_verify_control( opts, responses, &block )
                    end
                end
            end
        end
    end

    def rdiff_verify_control( opts, responses, &block )
        control2          = nil
        received_requests = 0

        opts[:precision].times do

            # Get the default response.
            audit( opts[:false], opts ) do |res, _, elem|
                if res.body.to_s.empty?
                    print_bad 'Server returned empty response body, aborting analysis.'
                    next
                end

                received_requests += 1

                if control2
                    print_status 'Got control verification response.'
                end

                # Remove context-irrelevant dynamic content like banners and such.
                control2 = (control2 ? control2.rdiff( res.body ) : res.body)

                next if received_requests != opts[:precision]
                if !rdiff_similar_bodies( responses[:controls][elem.altered], control2, opts[:ratio] )
                    print_bad 'Control baseline too unstable, aborting analysis.'
                    next
                end

                print_status 'Control baseline verified, continuing analysis.'
                rdiff_analyze_data( opts, responses, &block )
            end
        end
    end

    def rdiff_analyze_data( opts, responses, &block )
        controls = responses.delete( :controls )

        responses.each do |pair, data|
            if block
                exception_jail( false ){ block.call( pair, data ) }
                next
            end

            data.each do |input_name, result|

                # if default_response_body == true_response_body AND
                #    false_response_body != true_response_code AND
                #    true_response_code == 200
                if rdiff_similar_bodies( controls[input_name], result[:false], opts[:ratio] ) &&
                    !rdiff_similar_bodies( result[:false], result[:true], opts[:ratio] ) &&
                    result[:response].code == 200

                    # Check to see if the `true` response we're analyzing
                    # is a custom 404 page.
                    http.custom_404?( result[:response] ) do |custom_404|
                        # If this is a custom 404 page bail out.
                        next if custom_404

                        @auditor.log({
                                var:      input_name,
                                opts:     {
                                    injected_orig: result[:injected_string],
                                    combo:         result[:mutation].auditable
                                },
                                injected: result[:mutation].altered_value,
                                elem:     type
                            }, result[:response]
                        )
                    end
                end
            end
        end
    end

    def rdiff_similar_bodies( body1, body2, ratio )
        body1 == body2
    end

end
end
end
end
