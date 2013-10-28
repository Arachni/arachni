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
    # @param    [Block]     block
    #   To be used for custom analysis of gathered data.
    #
    # @return   [Bool]
    #   `true` if the audit was scheduled successfully, `false` otherwise (like
    #   if the resource is out of scope or already audited).
    #
    def rdiff_analysis( opts = {}, &block )
        return false if audited? audit_id
        audited audit_id

        if skip_path? self.action
            print_debug "Element's action matches skip rule, bailing out."
            return false
        end

        opts = self.class::MUTATION_OPTIONS.merge( RDIFF_OPTIONS.merge( opts ) )

        # Holds all the data from the probes.
        responses = {
            # Control baseline per input.
            controls:              {},

            # Verification control baseline per input.
            controls_verification: {},

            # Corrupted baselines per input.
            corrupted:             {}

            # Rest of the data are dynamically populated using input pairs
            # as keys.
        }

        # Populate the baseline/control forced-false responses.
        rdiff_establish_control( opts, responses )

        # Populate the 'true' responses.
        rdiff_fire_true_probes( opts, responses )

        # Populate the 'false' responses.
        rdiff_fire_false_probes( opts, responses )

        http.after_run do
            # Lastly, we need to re-establish a new baseline in order to compare
            # it with the initial one so as to be sure that server behavior
            # hasn't suddenly changed in a way that would corrupt our analysis.
            rdiff_verify_control( opts, responses )

            # Once the new baseline has been established and we've got all the
            # data we need, crunch them and see if server behavior is indicates
            # a vulnerability.
            http.after_run { rdiff_analyze_data( responses, &block ) }
        end

        true
    end

    private

    def rdiff_establish_control( opts, responses )
        opts[:precision].times do
            audit( opts[:false], opts ) do |res, _, elem|
                next if responses[:corrupted][elem.altered]

                if res.body.to_s.empty?
                    print_bad 'Server returned empty response body, aborting analysis.'
                    responses[:corrupted][elem.altered] = true
                    next
                end

                if responses[:controls][elem.altered]
                    print_status "Got default/control response for #{elem.type} " +
                        "variable '#{elem.altered}' with action '#{elem.action}'."
                end

                # Remove context-irrelevant dynamic content like banners and such.
                responses[:controls][elem.altered] =
                    responses[:controls][elem.altered] ?
                        responses[:controls][elem.altered].rdiff( res.body ).hash : res.body
            end
        end
    end

    def rdiff_fire_true_probes( opts, responses )
        opts[:pairs].each do |pair|
            responses[pair] ||= {}
            true_expr = pair.to_a.first[0]

            opts[:precision].times do
                audit( true_expr, opts ) do |res, _, elem|
                    responses[pair][elem.altered] ||= {}

                    next if responses[pair][elem.altered][:corrupted] ||
                        responses[:corrupted][elem.altered]

                    if res.body.to_s.empty?
                        print_bad 'Server returned empty response body,' <<
                            " aborting analysis for #{elem.type} variable " <<
                            "'#{elem.altered}' with action '#{elem.action}'."
                        responses[pair][elem.altered][:corrupted] = true
                        responses[:corrupted][elem.altered]       = true
                        next
                    end

                    if responses[pair][elem.altered][:true]
                        elem.print_status "Gathering data for #{elem.type} " <<
                            "variable '#{elem.altered}' with action '#{elem.action}'" <<
                            " -- Got true  response: #{true_expr}"
                    end

                    responses[pair][elem.altered][:mutation] = elem

                    # Keep the latest response for the {Arachni::Issue}.
                    responses[pair][elem.altered][:response]        = res
                    responses[pair][elem.altered][:injected_string] = true_expr

                    # Remove context-irrelevant dynamic content like banners
                    # and such from the error page.
                    responses[pair][elem.altered][:true] =
                        responses[pair][elem.altered][:true] ?
                            responses[pair][elem.altered][:true].rdiff( res.body.dup ).hash : res.body
                end
            end
        end
    end

    def rdiff_fire_false_probes( opts, responses )
        opts[:pairs].each do |pair|
            false_expr = pair.to_a.first[1]

            opts[:precision].times do
                audit( false_expr, opts ) do |res, _, elem|
                    responses[pair][elem.altered] ||= {}

                    next if responses[pair][elem.altered][:corrupted] ||
                        responses[:corrupted][elem.altered]

                    if res.body.to_s.empty?
                        print_status 'Server returned empty response body,' <<
                            " aborting analysis for #{elem.type} variable " <<
                            "'#{elem.altered}' with action '#{elem.action}'."
                        responses[pair][elem.altered][:corrupted] = true
                        responses[:corrupted][elem.altered]       = true
                        next
                    end

                    if responses[pair][elem.altered][:false]
                        elem.print_status "Gathering data for #{elem.type} " <<
                            "variable '#{elem.altered}' with action '#{elem.action}'" <<
                            " -- Got false response: #{false_expr}"
                    end

                    # Remove context-irrelevant dynamic content like banners
                    # and such from the error page.
                    responses[pair][elem.altered][:false] =
                        responses[pair][elem.altered][:false] ?
                            responses[pair][elem.altered][:false].rdiff( res.body.dup ).hash : res.body
                end
            end
        end
    end

    def rdiff_verify_control( opts, responses )
        opts[:precision].times do
            audit( opts[:false], opts ) do |res, _, elem|
                next if responses[:corrupted][elem.altered]

                if res.body.to_s.empty?
                    print_bad 'Server returned empty response body, aborting analysis ' <<
                        "for #{elem.type} variable '#{elem.altered}' with action '#{elem.action}'."
                    responses[:corrupted][elem.altered] = true
                    next
                end

                if responses[:controls_verification][elem.altered]
                    print_status 'Got control verification response ' <<
                        "for #{elem.type} variable '#{elem.altered}' with action '#{elem.action}'."
                end

                # Remove context-irrelevant dynamic content like banners and such.
                responses[:controls_verification][elem.altered] =
                    responses[:controls_verification][elem.altered] ?
                        responses[:controls_verification][elem.altered].rdiff( res.body ).hash : res.body

            end
        end
    end

    def rdiff_analyze_data( responses, &block )
        controls              = responses.delete( :controls )
        controls_verification = responses.delete( :controls_verification )
        corrupted             = responses.delete( :corrupted )

        responses.each do |pair, data|
            if block
                exception_jail( false ){ block.call( pair, data ) }
                next
            end

            data.each do |input_name, result|
                next if result[:corrupted] || corrupted[input_name]

                # If the initial and verification baselines differ, bail out;
                # server behavior is too unstable.
                if controls[input_name] != controls_verification[input_name]
                    result[:mutation].print_bad 'Control baseline too unstable, ' <<
                        "aborting analysis for #{result[:mutation].type} " <<
                        "variable '#{result[:mutation].altered}' with action " <<
                        "'#{result[:mutation].action}'"
                    next
                end

                # Log if:
                #
                #   force_false_baseline == false_response_body AND
                #   false_response_body != true_response_code AND
                #   true_response_code == 200
                next if controls[input_name] != result[:false] ||
                    result[:false] == result[:true] ||
                    result[:response].code != 200

                # Check to see if the `true` response we're analyzing
                # is a custom 404 page.
                http.custom_404?( result[:response] ) do |is_custom_404|
                    # If this is a custom 404 page bail out.
                    next if is_custom_404

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
end
end
end
