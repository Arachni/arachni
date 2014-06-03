=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Element::Capabilities
module Analyzable

# Evaluates whether or not the injection of specific data affects the response
# time of the web application.
#
# It takes into account unstable network conditions and server-side failures and
# verifies the results before logging.
#
# # Methodology
#
# Here's how it works:
#
# * Phase 1 ({#timeout_analysis}) -- We're picking the low hanging
#   fruit here so we can run this in larger concurrent bursts which cause *lots*
#   of noise.
#   - Initial probing for candidates -- If element times-out it is added to the
#       Phase 2 queue.
# * Phase 2 ({.analysis_phase_2}) -- {#timing_attack_verify Verifies} the
#   candidates. This is much more delicate so the concurrent requests are lowered
#   to pairs.
#   - Liveness test -- Ensures that the webapp is alive and not just timing-out
#       by default.
#   - Verification using an increased timeout delay -- Any elements that time out
#       again are logged.
#   - Stabilization ({#responsive?}).
# * Phase 3 ({.analysis_phase_3}) -- Same as phase 2 but with a higher
#   delay to ensure that false-positives are truly weeded out.
#
# Ideally, all requests involved with timing attacks would be run in sync mode
# but the performance penalties are too high, thus we compromise and make the best of it
# by running as little an amount of concurrent requests as possible for any given phase.
#
# # Usage
#
# * Call {#timeout_analysis} to schedule requests for Phase 1.
# * Call {Arachni::HTTP::Client#run} to run the Phase 1 requests which will populate
#   the Phase 2 queue with candidates -- if there are any.
# * Call {timeout_audit_run} to filter the candidates through Phases 2 and 3
#   to ensure that false-positives are weeded out.
#
# Be sure to call {timeout_audit_run} as soon as possible after Phase 1 as the
# candidate elements keep a reference to their auditor which will prevent it
# from being reaped by the garbage collector.
#
# This deviates from the normal framework structure because it is preferable
# to run timeout audits separately in order to avoid interference by other
# audit operations.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Timeout

    class <<self
        def reset
            @candidates_phase_2    = []
            @phase_2_candidate_ids = Support::LookUp::HashSet.new

            @candidates_phase_3    = []
            @phase_3_candidate_ids = Support::LookUp::HashSet.new

            deduplicate
        end

        def deduplicate?
            @deduplicate
        end

        def deduplicate
            @deduplicate = true
        end

        # Used just for specs of timing-attack checks.
        def do_not_deduplicate
            @deduplicate = false
        end

        def has_candidates?
            @candidates_phase_2.any?
        end

        def candidates_include?( candidate )
            @phase_2_candidate_ids.include? candidate.audit_id
        end

        def add_phase_2_candidate( elem )
            @phase_2_candidate_ids << elem.audit_id
            @candidates_phase_2    << elem
        end

        def add_phase3_candidate( elem )
            @phase_3_candidate_ids << elem.audit_id
            @candidates_phase_3    << elem
        end

        # Verifies and logs candidate elements.
        def run
            while !@candidates_phase_2.empty?
                analysis_phase_2( @candidates_phase_2.pop )
            end

            while !@candidates_phase_3.empty?
                analysis_phase_3( @candidates_phase_3.pop )
            end
        end

        # (Called by {.run}, do *NOT* call manually.)
        #
        # Runs phase 2 of the timing attack auditing an individual element
        # (which passed phase 1) with a higher delay and timeout.
        def analysis_phase_2( elem )
            delay = elem.audit_options[:delay] * 2

            elem.print_status "Phase 2 for #{elem.type} input '#{elem.affected_input_name}' " <<
                             "with action #{elem.action}"

            elem.timing_attack_verify( delay ) do |mutation|
                elem.print_info '* Verification was successful, candidate can ' <<
                                    'progress to Phase 2.'

                add_phase3_candidate( mutation )
            end
        end

        def analysis_phase_3( elem )
            delay = elem.audit_options[:delay] * 2

            elem.print_status "Phase 3 for #{elem.type} input '#{elem.affected_input_name}' " <<
                             "with action #{elem.action}"

            elem.timing_attack_verify( delay ) do |mutation, response|
                elem.print_info '* Verification was successful.'
                elem.auditor.log vector: mutation, response: response
            end
        end
    end

    # Performs timeout/time-delay analysis and logs an issue should there be one.
    #
    # @param  [String, Array<String>, Hash{Symbol => <String, Array<String>>}]  payloads
    #   Payloads to inject, if given:
    #
    #   * {String} -- Will inject the single payload.
    #   * {Array} -- Will iterate over all payloads and inject them.
    #   * {Hash} -- Expects {Platform} (as `Symbol`s ) for keys and {Array} of
    #       `payloads` for values. The applicable `payloads` will be
    #       {Platform::Manager#pick picked} from the hash based on
    #       {Element::Capabilities::Submittable#platforms applicable platforms}
    #       for the {Element::Capabilities::Submittable#action resource} to be audited.
    #
    #   Delay placeholder `__TIME__` will be substituted with `timeout / timeout_divider`.
    # @param   [Hash]      opts
    #   Options as described in {Element::Capabilities::Mutable::MUTATION_OPTIONS}
    #   with the specified extras.
    # @option   opts    [Integer] :timeout
    #   Milliseconds to wait for the request to complete.
    # @option   opts    [Integer] :timeout_divider (1)
    #   `__TIME__ = timeout / timeout_divider`
    # @option   opts    [Integer] :add (0)
    #   Add this integer to the expected time the request is supposed to take,
    #   in milliseconds.
    #
    # @return   [Bool]
    #   `true` if the audit was scheduled successfully, `false` otherwise (like
    #   if the resource is out of scope).
    def timeout_analysis( payloads, opts )
        return false if self.inputs.empty?

        if skip_path? self.action
            print_debug "Timeout analysis: Element's action matches " <<
                            "skip rule, bailing out: #{audit_id}"
            return false
        end

        timing_attack_probe( payloads, opts ) do |elem|
            elem.auditor = @auditor

            next if Timeout.deduplicate? && Timeout.candidates_include?( elem )

            print_info 'Found a candidate for Phase 2 -- ' <<
                "#{elem.type.capitalize} input '#{elem.affected_input_name}' at #{elem.action}"
            Timeout.add_phase_2_candidate( elem )
        end

        true
    end

    # Submits self with a high timeout value and blocks until it gets a response.
    #
    # This is to make sure that responsiveness has been restored before
    # progressing further in the timeout analysis.
    #
    # @param    [Integer] limit
    #   How many milliseconds to afford the server to respond.
    #
    # @return   [Bool]
    #   `true` if server responds within the given time limit, `false` otherwise.
    def responsive?( limit = 120_000, prepend = '* ' )
        d_opts = {
            skip_original:     true,
            redundant:         true,
            timeout:           limit,
            silent:            true,
            mode:              :sync,
            response_max_size: 0
        }

        orig_opts = @audit_options.dup

        print_info "#{prepend}Waiting for the effects of the timing attack to " <<
            'wear off, this may take a while (max waiting time is ' <<
             "#{d_opts[:timeout] / 1000.0} seconds)."

        @auditable = @default_inputs.dup
        res = submit( d_opts )

        @audit_options.merge!( orig_opts )

        if res.timed_out?
            print_bad "#{prepend}Max waiting time exceeded."
            false
        else
            true
        end
    end

    # Performs a simple probe for elements whose submission results in a
    # response time that matches the delay criteria in `options`.
    #
    # @param    (see #timeout_analysis)
    def timing_attack_probe( payloads, options, &block )
        fail ArgumentError, 'Missing block' if !block_given?

        options                     = options.dup
        options[:delay]             = options.delete(:timeout)
        options[:timeout_divider] ||= 1
        options[:add]             ||= 0

        # Ignore response bodies to preserve bandwidth since we don't care
        # about them anyways.
        options[:submit] = { response_max_size: 0 }

        # Intercept each element mutation prior to it being submitted and replace
        # the '__TIME__' placeholder with the actual delay value.
        each_mutation = proc do |mutation|
            injected = mutation.affected_input_value

            # Preserve the original because it's going to be needed for the
            # verification phases.
            mutation.audit_options[:timing_string] = injected

            mutation.affected_input_value = injected.
                gsub( '__TIME__', (options[:delay] / options[:timeout_divider]).to_s )
        end

        options.merge!( each_mutation: each_mutation, skip_original: true )

        audit( payloads, options ) do |response, mutation|
            next if response.app_time < (options[:delay] + options[:add]) / 1000.0
            block.call( mutation, response )
        end
    end

    # Verifies that response times are controllable for elements picked by
    # {#timing_attack_probe}.
    #
    # * Liveness check: Element is submitted as is with a  very high timeout
    #   value, to make sure that (or wait until) the server is alive and {#responsive?}.
    # * Control check: Element is, again,  submitted as is, although this time
    #   with a timeout value of `delay` to ensure that the server is stable
    #   enough to be checked.
    #   * If this fails the check is aborted.
    # * Verification: Element is submitted with an increased delay to verify
    #   the vulnerability.
    #   * If verification succeeds the `block` is called.
    # * Stabilize responsiveness: Wait for the effects of the timing attack
    #   to wear off by calling {#responsive?}.
    #
    # @param    [Integer]   delay
    # @param    [Block]     block
    def timing_attack_verify( delay, &block )
        fail ArgumentError, 'Missing block' if !block_given?

        opts         = self.audit_options
        opts[:delay] = delay

        payload = opts[:timing_string].dup
        payload.gsub!( '__TIME__', (opts[:delay] / opts[:timeout_divider]).to_s )

        self.inputs = self.default_inputs

        # Make sure we're starting off with a clean slate.
        responsive?

        print_info '* Performing liveness check.'

        # This is the control; request the URL of the element to make sure
        # that the web page is responsive i.e won't time-out by default.
        submit( response_max_size: 0, timeout: opts[:delay] ) do |control_response|
            # Remove the timeout option set by the liveness check in order
            # to now affect later requests.
            self.audit_options.delete( :timeout )

            if control_response.timed_out?
                print_info '* Liveness check failed, aborting.'
                next
            end

            print_info '* Liveness check was successful, progressing' <<
                                ' to verification.'

            opts.merge!(
                skip_like: proc do |m|
                    m.affected_input_name != affected_input_name
                end,
                format:    [Mutable::Format::STRAIGHT],
                silent:    true
            )

            audit( payload, opts ) do |response, mutation|
                if response.app_time.round < (opts[:delay] + opts[:add]) / 1000.0
                    print_info '* Verification failed.'
                    next
                end

                block.call( mutation, response )

                responsive?
            end
        end

        http.run
    end

end
end
end
end
