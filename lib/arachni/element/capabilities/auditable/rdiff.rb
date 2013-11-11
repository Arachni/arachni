=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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
    #
    # @return   [Bool]
    #   `true` if the audit was scheduled successfully, `false` otherwise (like
    #   if the resource is out of scope or already audited).
    #
    def rdiff_analysis( opts = {} )
        return if self.auditable.empty?

        return false if audited? audit_id
        audited audit_id

        if skip_path? self.action
            print_debug "Element's action matches skip rule, bailing out."
            return false
        end

        opts = self.class::MUTATION_OPTIONS.merge( RDIFF_OPTIONS.merge( opts ) )

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
            populate_true_signatures( opts, signatures )

            # Populate the 'false' signatures.
            populate_false_signatures( opts, signatures )
        end

        true
    end

    private

    # Performs requests using the 'false' control seed and generates/stores
    # signatures based on the response bodies.
    def populate_control_signatures( opts, signatures )
        gathered = {}
        opts[:precision].times do
            audit( opts[:false], opts ) do |res, _, elem|
                altered_hash = elem.altered.hash

                next if signatures[:corrupted][altered_hash]

                gathered[altered_hash] ||= 0
                gathered[altered_hash]  += 1

                response_check( res, signatures, elem )

                if gathered[altered_hash] == @data_gathering[:mutations_size]
                    print_status "Got default/control response for #{elem.type} " +
                        "variable '#{elem.altered}' with action '#{elem.action}'."

                    @data_gathering[:controls][altered_hash] = true
                end

                # Create a signature from the response body and refine it with
                # subsequent ones to remove noise (like context-irrelevant dynamic
                # content such as banners etc.).
                signatures[:controls][altered_hash] =
                    signatures[:controls][altered_hash] ?
                        signatures[:controls][altered_hash].refine!(res.body) :
                        Support::Signature.new(res.body)

                @data_gathering[:received_responses] += 1

                finalize_if_done( opts, signatures )
            end
        end
    end

    # Performs requests using the 'true' seeds and generates/stores signatures
    # based on the response bodies.
    def populate_true_signatures( opts, signatures )
        gathered = {}

        opts[:pairs].each do |pair|
            pair_hash = pair.hash

            signatures[pair_hash]      ||= {}
            @data_gathering[pair_hash] ||= {}
            gathered[pair_hash]        ||= {}

            true_expr = pair.to_a.first[0]

            print_status "Gathering 'true'  data for #{self.type} with " <<
                "action '#{self.action}' using seed: #{true_expr}"

            opts[:precision].times do
                audit( true_expr, opts ) do |res, _, elem|
                    altered_hash = elem.altered.hash

                    gathered[pair_hash][altered_hash] ||= 0
                    gathered[pair_hash][altered_hash] += 1

                    signatures[pair_hash][altered_hash]      ||= {}
                    @data_gathering[pair_hash][altered_hash] ||= {}

                    next if signatures[pair_hash][altered_hash][:corrupted] ||
                        signatures[:corrupted][altered_hash]

                    response_check( res, signatures, elem, pair_hash )

                    next if signature_sieve( altered_hash, signatures, pair_hash )

                    if gathered[pair_hash][altered_hash] == opts[:precision]
                        elem.print_status "Got 'true'  response for #{elem.type} " <<
                            "variable '#{elem.altered}' with action '#{elem.action}'" <<
                            " using seed: #{true_expr}"
                        @data_gathering[pair_hash][altered_hash][:true_probes] = true
                    end

                    # Store the mutation for the {Arachni::Issue}.
                    signatures[pair_hash][altered_hash][:mutation] = elem

                    # Keep the latest response for the {Arachni::Issue}.
                    signatures[pair_hash][altered_hash][:response] = res

                    signatures[pair_hash][altered_hash][:injected_string] = true_expr

                    # Create a signature from the response body and refine it with
                    # subsequent ones to remove noise (like context-irrelevant dynamic
                    # content such as banners etc.).
                    signatures[pair_hash][altered_hash][:true] =
                        signatures[pair_hash][altered_hash][:true] ?
                            signatures[pair_hash][altered_hash][:true].refine!(res.body) :
                            Support::Signature.new(res.body)

                    signature_sieve( altered_hash, signatures, pair_hash )

                    @data_gathering[:received_responses] += 1
                    finalize_if_done( opts, signatures )
                end
            end
        end
    end

    # Performs requests using the 'false' seeds and generates/stores signatures
    # based on the response bodies.
    def populate_false_signatures( opts, signatures )
        gathered = {}

        opts[:pairs].each do |pair|
            pair_hash = pair.hash

            signatures[pair_hash]      ||= {}
            @data_gathering[pair_hash] ||= {}
            gathered[pair_hash]        ||= {}

            false_expr = pair.to_a.first[1]

            print_status "Gathering 'false' data for #{self.type} with " <<
                "action '#{self.action}' using seed: #{false_expr}"

            opts[:precision].times do
                audit( false_expr, opts ) do |res, _, elem|
                    altered_hash = elem.altered.hash

                    gathered[pair_hash][altered_hash] ||= 0
                    gathered[pair_hash][altered_hash] += 1

                    signatures[pair_hash][altered_hash]      ||= {}
                    @data_gathering[pair_hash][altered_hash] ||= {}

                    next if signatures[pair_hash][altered_hash][:corrupted] ||
                        signatures[:corrupted][altered_hash]

                    response_check( res, signatures, elem, pair_hash )

                    next if signature_sieve( altered_hash, signatures, pair_hash )

                    if gathered[pair_hash][altered_hash] == opts[:precision]
                        elem.print_status "Got 'false' response for #{elem.type} " <<
                            "variable '#{elem.altered}' with action '#{elem.action}'" <<
                            " using seed: #{false_expr}"
                        @data_gathering[pair_hash][altered_hash][:false_probes] = true
                    end

                    # Create a signature from the response body and refine it with
                    # subsequent ones to remove noise (like context-irrelevant dynamic
                    # content such as banners etc.).
                    signatures[pair_hash][altered_hash][:false] =
                        signatures[pair_hash][altered_hash][:false] ?
                            signatures[pair_hash][altered_hash][:false].refine!(res.body) :
                            Support::Signature.new(res.body)

                    signature_sieve( altered_hash, signatures, pair_hash )

                    @data_gathering[:received_responses] += 1
                    finalize_if_done( opts, signatures )
                end
            end
        end
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
            audit( opts[:false], opts ) do |res, _, elem|
                altered_hash = elem.altered.hash

                gathered[altered_hash] ||= 0
                gathered[altered_hash]  += 1

                next if signatures[:corrupted][altered_hash]

                response_check( res, signatures, elem )

                if gathered[altered_hash] == opts[:precision]
                    print_status 'Got control verification response ' <<
                        "for #{elem.type} variable '#{elem.altered}' with" <<
                        " action '#{elem.action}'."
                end

                # Create a signature from the response body and refine it with
                # subsequent ones to remove noise (like context-irrelevant dynamic
                # content such as banners etc.).
                signatures[:controls_verification][altered_hash] =
                    signatures[:controls_verification][altered_hash] ?
                        signatures[:controls_verification][altered_hash].refine!(res.body) :
                        Support::Signature.new(res.body)

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

        signatures.each do |_, data|
            data.each do |input, result|
                next if result[:corrupted] || corrupted[input]

                # If the initial and verification baselines differ, bail out;
                # server behavior is too unstable.
                if controls[input] != controls_verification[input]
                    result[:mutation].print_bad 'Control baseline too unstable, ' <<
                        "aborting analysis for #{result[:mutation].type} " <<
                        "variable '#{result[:mutation].altered}' with action " <<
                        "'#{result[:mutation].action}'"
                    next
                end

                # To have gotten here the following must be true:
                #
                #   force_false_baseline == false_response_body AND
                #   false_response_body != true_response_code AND
                #   true_response_code == 200

                # Check to see if the `true` response we're analyzing
                # is a custom 404 page.
                http.custom_404?( result[:response] ) do |is_custom_404|
                    # If this is a custom 404 page bail out.
                    next if is_custom_404

                    @auditor.log({
                            var:      result[:mutation].altered,
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

    def response_check( response, signatures, elem, pair = nil )
        corrupted = false

        if response.code != 200
            print_status 'Server returned non 200 status,' <<
                " aborting analysis for #{elem.type} variable " <<
                "'#{elem.altered}' with action '#{elem.action}'."
            corrupted = true
        end

        if response.body.to_s.empty?
            print_status 'Server returned empty response body,' <<
                " aborting analysis for #{elem.type} variable " <<
                "'#{elem.altered}' with action '#{self.action}'."
            corrupted = true
        end

        return if !corrupted

        if pair
            signatures[pair][elem.altered.hash][:corrupted] = true
        else
            signatures[:corrupted][elem.altered.hash] = true
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
        if (@data_gathering[:controls][input] && gathered[:false_probes]) &&
            (signatures[:controls][input] != signature[:false])
            signatures[pair].delete( input )
            return true
        end

        # 2nd check: force_false_baseline != true_response_code
        if (gathered[:false_probes] && gathered[:true_probes]) &&
            (signature[:false] == signature[:true])
            signatures[pair].delete( input )
            return true
        end

        false
    end

end
end
end
end
