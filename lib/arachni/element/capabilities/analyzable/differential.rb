=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative '../mutable'

module Arachni
module Element::Capabilities
module Analyzable

# Performs boolean injection and behavioral analysis (using differential analysis
# techniques based on {Support::Signature} comparisons) in order to determine
# whether the web application is responding to the injected data and how.
#
# If the behavior can be manipulated by the injected data in ways that it's not
# supposed to (like when evaluating injected code) then the element is deemed
# vulnerable.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Differential

    class <<self
        def reset
            # In case we want to reset state or something...
        end
    end

    DIFFERENTIAL_OPTIONS =  {
        format:         [Arachni::Element::Capabilities::Mutable::Format::STRAIGHT],

        # Amount of refinement operations to remove context-irrelevant dynamic
        # content -- like banners etc.
        precision:      2,

        # Override global fuzzing settings and only use the default method of
        # the element under audit.
        with_raw_payloads:      false,
        with_both_http_methods: false,
        parameter_names:        false,
        with_extra_parameter:   false,

        # Disable {Arachni::Options#audit_cookies_extensively}, there's little
        # to be gained in this case and just causes interference.
        extensively:    false,

        # Don't generate or submit any mutations with default or sample inputs.
        skip_original:  true,

        # Allow redundant audits, we need multiple ones for noise-reduction.
        redundant:      true,

        # Don't let #audit print output, we'll handle that ourselves.
        silent:         true,

        # Default value for a forceful 'false' response.
        false:          '-1'
    }

    DIFFERENTIAL_ALLOWED_STATUS = Set.new([200, 404])

    attr_accessor :differential_analysis_options

    # Performs differential analysis and logs an issue should there be one.
    #
    #     opts = {
    #         false: 'false resource id',
    #         pairs: [
    #               { 'true expression' => 'false expression' }
    #         ]
    #     }
    #
    #     element.differential_analysis( opts )
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
    #   Amount of refinement iterations to perform for the signatures.
    # @option   opts    [Array<Hash>] :pairs
    #   Pair of strings that should yield different results when interpreted.
    #   Keys should be the `true` expressions.
    # @option   opts    [String]       :false
    #   A string which would illicit a 'false' response but without any code.
    #
    # @return   [Bool]
    #   `true` if the audit was scheduled successfully, `false` otherwise (like
    #   if the resource is out of scope or already audited).
    def differential_analysis( opts = {} )
        return if self.inputs.empty?

        with_missing_values = Set.new( self.inputs.select { |k, v| v.to_s.empty? }.keys )
        if self.inputs.size == with_missing_values.size
            print_debug 'Differential analysis: Inputs are missing default values.'
            return false
        end

        return false if audited? audit_id
        audited audit_id

        if scope.out?
            print_debug 'Differential analysis: Element is out of scope,' <<
                            " skipping: #{audit_id}"
            return false
        end

        @differential_analysis_options = opts.dup
        opts = self.class::MUTATION_OPTIONS.merge( DIFFERENTIAL_OPTIONS.merge( opts ) )
        opts[:skip_like] = proc do |mutation|
            with_missing_values.include? mutation.affected_input_name
        end

        mutations_size = 0
        each_mutation( opts[:false], opts ) { mutations_size += 1 }
        mutations_size *= opts[:precision]

        @data_gathering = {
            mutations_size:     mutations_size,
            expected_responses: mutations_size + (mutations_size * opts[:pairs].size * 2),
            received_responses: 0,
            done:               false,
            controls:           {}
        }

        # Holds all the data from the probes.
        signatures = {
            # Control baseline per input.
            controls:              {},

            # Verification control baseline per input.
            controls_verification: {},

            # Corrupted baselines per input.
            corrupted:             {},

            # Rest of the data are dynamically populated using input pairs
            # as keys.
        }

        # Populate the baseline/control forced-false signatures.
        populate_control_signatures( opts, signatures )

        http.after_run do
            # Populate the 'true' signatures.
            populate_signatures( :true, opts, signatures )

            # Populate the 'false' signatures.
            populate_signatures( :false, opts, signatures )
        end

        true
    end

    def dup
        e = super
        return e if !@differential_analysis_options

        e.differential_analysis_options = @differential_analysis_options.dup
        e
    end

    def to_rpc_data
        super.tap { |data| data.delete 'differential_analysis_options' }
    end

    private

    # Performs requests using the 'false' control seed and generates/stores
    # signatures based on the response bodies.
    def populate_control_signatures( opts, signatures )
        gathered = {}
        opts[:precision].times do
            audit( opts[:false], opts ) do |res, elem|
                altered_hash = elem.affected_input_name.hash

                if signatures[:corrupted][altered_hash]
                    increase_received_responses( opts, signatures )
                    next
                end

                gathered[altered_hash] ||= 0
                gathered[altered_hash]  += 1

                response_check( res, signatures, elem )

                if gathered[altered_hash] == @data_gathering[:mutations_size]
                    print_status "Got default/control response for #{elem.type} " +
                        "variable '#{elem.affected_input_name}' with action '#{elem.action}'."

                    @data_gathering[:controls][altered_hash] = true
                end

                body = res.body.gsub( elem.seed, '' )

                # Create a signature from the response body and refine it with
                # subsequent ones to remove noise (like context-irrelevant dynamic
                # content such as banners etc.).
                signatures[:controls][altered_hash] =
                    signatures[:controls][altered_hash] ?
                        signatures[:controls][altered_hash].refine!(body) :
                        Support::Signature.new(body)

                increase_received_responses( opts, signatures )
            end
        end
    end

    def populate_signatures( bool, opts, signatures )
        gathered = {}

        opts[:pairs].each do |pair|
            pair_hash = pair.hash

            signatures[pair_hash]      ||= {}
            @data_gathering[pair_hash] ||= {}
            gathered[pair_hash]        ||= {}

            expr = pair.to_a.first[bool == :true ? 0 : 1]

            print_status "Gathering '#{bool}' data for #{self.type} with " <<
                             "action '#{self.action}' using seed: #{expr}"

            opts[:precision].times do
                audit( expr, opts ) do |res, elem|
                    altered_hash = elem.affected_input_name.hash

                    gathered[pair_hash][altered_hash] ||= 0
                    gathered[pair_hash][altered_hash] += 1

                    signatures[pair_hash][altered_hash]      ||= {}
                    @data_gathering[pair_hash][altered_hash] ||= {}

                    response_check( res, signatures, elem )

                    if signatures[pair_hash][altered_hash][:corrupted] ||
                        signatures[:corrupted][altered_hash]

                        increase_received_responses( opts, signatures )
                        next
                    end

                    if signature_sieve( altered_hash, signatures, pair_hash )
                        increase_received_responses( opts, signatures )
                        next
                    end

                    if gathered[pair_hash][altered_hash] == opts[:precision]
                        elem.print_status "Got '#{bool}' response for #{elem.type}" <<
                            " variable '#{elem.affected_input_name}' with action" <<
                            " '#{elem.action}' using seed: #{expr}"

                        @data_gathering[pair_hash][altered_hash]["#{bool}_probes".to_sym] = true
                    end

                    # Store the mutation for the {Arachni::Issue}.
                    signatures[pair_hash][altered_hash][:mutation] ||= elem

                    # Keep the latest response for the {Arachni::Issue}.
                    signatures[pair_hash][altered_hash][:response] ||= res

                    signatures[pair_hash][altered_hash][:injected_string] ||= expr

                    body = res.body.gsub( elem.seed, '' )

                    # Create a signature from the response body and refine it with
                    # subsequent ones to remove noise (like context-irrelevant dynamic
                    # content such as banners etc.).
                    signatures[pair_hash][altered_hash][bool] =
                        signatures[pair_hash][altered_hash][bool] ?
                            signatures[pair_hash][altered_hash][bool].refine!(body) :
                            Support::Signature.new(body)

                    signature_sieve( altered_hash, signatures, pair_hash )

                    increase_received_responses( opts, signatures )
                end
            end
        end
    end

    def increase_received_responses( opts, signatures )
        @data_gathering[:received_responses] += 1
        finalize_if_done( opts, signatures )
    end

    # Check if we're done with data gathering and proceed to establishing a
    # {#populate_control_verification_signatures verification control baseline}
    # and {#match_signatures final analysis}.
    def finalize_if_done( opts, signatures )
        return if @data_gathering[:done] ||
            @data_gathering[:expected_responses] != @data_gathering[:received_responses]
        @data_gathering[:done] = true

        # Lastly, we need to re-establish a new baseline in order to compare
        # it with the initial one so as to be sure that server behavior
        # hasn't suddenly changed in a way that would corrupt our analysis.
        populate_control_verification_signatures( opts, signatures )
    end

    # Re-establishes a control baseline at the end of the audit, to make sure
    # that website behavior has remained stable, otherwise its behavior won't
    # be trustworthy.
    def populate_control_verification_signatures( opts, signatures )
        received_responses = 0
        gathered           = {}

        opts[:precision].times do
            audit( opts[:false], opts ) do |res, elem|
                altered_hash = elem.affected_input_name.hash

                gathered[altered_hash] ||= 0
                gathered[altered_hash]  += 1

                response_check( res, signatures, elem )

                if signatures[:corrupted][altered_hash]
                    @data_gathering[:received_responses] += 1
                    next
                end

                if gathered[altered_hash] == opts[:precision]
                    print_status 'Got control verification response ' <<
                        "for #{elem.type} variable '#{elem.affected_input_name}' with" <<
                        " action '#{elem.action}'."
                end

                body = res.body.gsub( elem.seed, '' )

                # Create a signature from the response body and refine it with
                # subsequent ones to remove noise (like context-irrelevant dynamic
                # content such as banners etc.).
                signatures[:controls_verification][altered_hash] =
                    signatures[:controls_verification][altered_hash] ?
                        signatures[:controls_verification][altered_hash].refine!(body) :
                        Support::Signature.new(body)

                received_responses += 1
                next if received_responses != @data_gathering[:mutations_size]

                # Once the new baseline has been established and we've got all the
                # data we need, crunch them and see if server behavior indicates
                # a vulnerability.
                match_signatures( signatures )
            end
        end
    end

    def match_signatures( signatures )
        controls              = signatures.delete( :controls )
        controls_verification = signatures.delete( :controls_verification )
        corrupted             = signatures.delete( :corrupted )

        signatures.each do |pair_hash, data|
            data.each do |input, result|
                next if !result[:response] || result[:corrupted] || corrupted[input]

                # If the initial and verification baselines differ, bail out;
                # server behavior is too unstable.
                if controls[input] != controls_verification[input]
                    result[:mutation].print_bad 'Control baseline too unstable, ' <<
                        "aborting analysis for #{result[:mutation].type} " <<
                        "variable '#{result[:mutation].affected_input_name}' " <<
                        "with action '#{result[:mutation].action}'"
                    next
                end

                # To have gotten here the following must be true:
                #
                #   force_false_baseline == false_response_body AND
                #   false_response_body != true_response_body AND
                #   force_false_response_code == 200 AND
                #   true_response_code == 200 AND
                #   false_response_code == 200

                # Check to see if the `true` response we're analyzing
                # is a custom 404 page.
                http.dynamic_404_handler._404?( result[:response] ) do |is_custom_404|
                    # If this is a custom 404 page bail out.
                    next if is_custom_404

                    options = result[:mutation].differential_analysis_options
                    pair    = options[:pairs].find { |pair| pair.hash == pair_hash }

                    issue_data = {
                        vector:   result[:mutation],
                        response: result[:response]
                    }

                    if pair
                        issue_data[:remarks] = {
                            :differential_analysis => [
                                "True expression: #{pair.keys.first}",
                                "False expression: #{pair.values.first}",
                                "Control false expression: #{options[:false]}"
                            ]
                        }
                    end

                    @auditor.log( issue_data )
                end
            end
        end
    end

    def response_check( response, signatures, elem, pair = nil )
        corrupted = false

        if !DIFFERENTIAL_ALLOWED_STATUS.include?( response.code )
            print_status "Server returned status (#{response.code})," <<
                " aborting analysis for #{elem.type} variable " <<
                "'#{elem.affected_input_name}' with action '#{elem.action}'."
            corrupted = true
        end

        if !corrupted && response.partial?
            print_status "Server returned partial response, aborting analysis " <<
                "for #{elem.type} variable '#{elem.affected_input_name}' with " <<
                "action '#{elem.action}'."
            corrupted = true
        end

        if !corrupted && response.body.empty?
            print_status 'Server returned empty response body,' <<
                " aborting analysis for #{elem.type} variable " <<
                "'#{elem.affected_input_name}' with action '#{self.action}'."
            corrupted = true
        end

        return if !corrupted

        if pair
            signatures[pair][elem.affected_input_name.hash][:corrupted] = true
        else
            signatures[:corrupted][elem.affected_input_name.hash] = true
        end
    end

    def signature_sieve( input, signatures, pair )
        gathered  = @data_gathering[pair][input]
        signature = signatures[pair][input]

        # If data has been corrupted for the given input, remove it.
        if signature[:corrupted]
            signatures[pair].delete( input )
            return true
        end

        # 1st check: force_false_baseline == false_response_body
        #
        #   * Make sure the necessary data has been gathered.
        #   * Remove the data if forced-false and boolean-false signatures
        #       don't match.
        if (@data_gathering[:controls][input] && gathered[:false_probes]) &&
            (signatures[:controls][input] != signature[:false])

            signatures[pair].delete( input )
            return true
        end

        # 2nd check: false_response_baseline != true_response_baseline
        #
        #   * Make sure the necessary data has been gathered.
        #   * Remove the data if boolean-false and boolean-true signatures
        #       are too similar.
        if (gathered[:false_probes] && gathered[:true_probes]) &&
            signature[:false].similar?( signature[:true], 0.1 )

            signatures[pair].delete( input )
            return true
        end

        false
    end

end
end
end
end
