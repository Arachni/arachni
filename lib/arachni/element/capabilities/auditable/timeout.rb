=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni::Element::Capabilities

module Auditable

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
#   fruit here so we can run this in larger concurrent bursts which cause *lots* of noise.
#   - Initial probing for candidates -- If element times-out it is added to the Phase 2 queue.
#   - Stabilization ({#responsive?}) -- The element is submitted with its default values in
#     order to wait until the effects of the timing attack have worn off.
# * Phase 2 ({.analysis_phase_2}) -- Verifies the candidates. This is much more delicate so the
#   concurrent requests are lowered to pairs.
#   - Liveness test -- Ensures that the webapp is alive and not just timing-out by default
#   - Verification using an increased timeout delay -- Any elements that time out again are logged.
#   - Stabilization ({#responsive?})
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
            @phase_2_candidate_ids = ::Arachni::Support::LookUp::HashSet.new

            @candidates_phase_3    = []
            @phase_3_candidate_ids = ::Arachni::Support::LookUp::HashSet.new

            deduplicate
        end

        def deduplicate?
            @deduplicate
        end

        def deduplicate
            @deduplicate = true
        end

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

        # (Called by {Timeout.run}, do *NOT* call manually.)
        #
        # Runs phase 2 of the timing attack auditing an individual element
        # (which passed phase 1) with a higher delay and timeout.
        #
        # * Liveness check: Element is submitted as is to make sure that the page is alive and responsive
        #   * If liveness check fails then phase 2 is aborted
        #   * If liveness check succeeds it progresses to verification
        # * Verification: Element is submitted with an increased delay to verify the vulnerability
        #   * If verification fails it aborts
        #   * If verification succeeds the issue is logged
        # * Stabilize responsiveness: Wait for the effects of the timing attack to wear off
        def analysis_phase_2( elem )
            opts          = elem.audit_options
            opts[:delay] *= 2

            str = opts[:timing_string].dup
            str.gsub!( '__TIME__', (opts[:delay] / opts[:timeout_divider]).to_s )

            elem.inputs = elem.original

            elem.print_status "Phase 2 for #{elem.type} input '#{elem.altered}'" <<
                                  " with action #{elem.action}"

            elem.print_info '* Performing liveness check.'

            # This is the control; request the URL of the element to make sure
            # that the web page is responsive i.e won't time-out by default.
            elem.submit( timeout: opts[:delay] ) do |res|
                # Remove the timeout option set by the liveness check in order
                # to now affect later requests.
                elem.audit_options.delete( :timeout )

                if res.timed_out?
                    elem.print_info '* Liveness check failed, aborting.'
                    next
                end

                elem.print_info '* Liveness check was successful, progressing' <<
                                    ' to verification.'

                opts[:skip_like] = proc { |m| m.altered != elem.altered }
                opts[:format]    = [Mutable::Format::STRAIGHT]
                opts[:silent]    = true

                elem.audit( str, opts ) do |c_res|
                    if c_res.app_time <= (opts[:delay] + opts[:add]) / 1000.0
                        elem.print_info '* Verification failed.'
                        next
                    end

                    elem.audit_options[:delay] = opts[:delay]

                    elem.print_info '* Verification was successful, ' <<
                                        'candidate can progress to Phase 3.'

                    add_phase3_candidate( elem )
                    elem.responsive?
                end
            end

            elem.http.run
        end

        def analysis_phase_3( elem )
            opts          = elem.audit_options
            opts[:delay] *= 2

            str = opts[:timing_string].dup
            str.gsub!( '__TIME__', (opts[:delay] / opts[:timeout_divider]).to_s )

            elem.inputs = elem.original

            elem.print_status "Phase 3 for #{elem.type} input '#{elem.altered}'" <<
                                  " with action #{elem.action}"

            elem.print_info '* Performing liveness check.'

            # This is the control; request the URL of the element to make sure
            # that the web page is alive i.e won't time-out by default.
            elem.submit( timeout: opts[:delay] ) do |res|
                if res.timed_out?
                    elem.print_info '* Liveness check failed.'
                    next
                end

                elem.print_info '* Liveness check was successful, progressing' <<
                                    ' to verification.'

                opts[:skip_like] = proc { |m| m.altered != elem.altered }
                opts[:format]    = [Mutable::Format::STRAIGHT]
                opts[:silent]    = true

                elem.audit( str, opts ) do |c_res, c_elem|
                    if c_res.app_time <= (opts[:delay] + opts[:add]) / 1000.0
                        elem.print_info '* Verification failed.'
                        next
                    end

                    elem.print_info '* Verification was successful.'
                    elem.auditor.log( c_elem.audit_options, c_res )
                    elem.responsive?
                end
            end

            elem.http.run
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
    #       {Platform#pick picked} from the hash based on
    #       {Element::Base#platforms applicable platforms} for the
    #       {Base#action resource} to be audited.
    #
    #   Delay placeholder `__TIME__` will be substituted with `timeout / timeout_divider`.
    # @param   [Hash]      opts
    #   Options as described in {Arachni::Element::Capabilities::Mutable::MUTATION_OPTIONS}
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
            print_debug "Element's action matches skip rule, bailing out."
            return false
        end

        delay = opts[:timeout]
        audit_timeout_debug_msg( 1, delay )
        timing_attack( payloads, opts ) do |elem|
            elem.auditor = @auditor

            next if Timeout.deduplicate? && Timeout.candidates_include?( elem )

            print_info 'Found a candidate for Phase 2 -- ' <<
                "#{elem.type.capitalize} input '#{elem.altered}' at #{elem.action}"
            Timeout.add_phase_2_candidate( elem )
        end

        true
    end

    # Submits self with a high timeout value and blocks until it gets a response.
    # This is to make sure that responsiveness has been restored before
    # progressing further.
    #
    # @param    [Integer] limit
    #   How many milliseconds to afford the server to respond.
    #
    # @return   [Bool]
    #   `true` if server responds within the given time limit, `false` otherwise.
    def responsive?( limit = 120_000, prepend = '* ' )
        d_opts = {
            skip_original: true,
            redundant:     true,
            timeout:       limit * 1000,
            silent:        true,
            mode:          :sync
        }

        orig_opts = @audit_options.dup

        print_info "#{prepend}Waiting for the effects of the timing attack to " <<
            'wear off, this may take a while (max waiting time is ' <<
             "#{d_opts[:timeout] / 1000.0} seconds)."

        @auditable = @original.dup
        res = submit( d_opts )

        @audit_options.merge!( orig_opts )

        if res.timed_out?
            print_bad 'Max waiting time exceeded.'
            false
        else
            true
        end
    end

    private

    def audit_timeout_debug_msg( phase, delay )
        print_debug '---------------------------------------------'
        print_debug "Running phase #{phase.to_s} of timing attack."
        print_debug "Delay set to: #{delay.to_s} milliseconds"
        print_debug '---------------------------------------------'
    end

    # Audits elements using a timing attack.
    #
    # 'opts' needs to contain a :timeout value in milliseconds.</br>
    # Optionally, you can add a :timeout_divider.
    #
    # @param   [String, Array, Hash{Symbol => String, Array<String>}]     payloads
    #   Injection strings (`__TIME__` will be substituted with
    #   `timeout / timeout_divider`).
    # @param    [Hash]      opts
    #   Options as described in {Arachni::Element::Mutable::OPTIONS}.
    # @param    [Block]     block
    #   Block to call if a timeout occurs, it will be passed the
    #   {Arachni::HTTP::Response response} and element mutation.
    def timing_attack( payloads, opts, &block )
        opts                     = opts.dup
        opts[:delay]             = opts.delete(:timeout)
        opts[:timeout_divider] ||= 1
        opts[:add]             ||= 0

        # Intercept each element mutation prior to it being submitted and replace
        # the '__TIME__' placeholder with the actual delay value.
        each_mutation = proc do |mutation|
            injected = mutation.altered_value

            # Preserve the original because it's going to be needed for the
            # verification phases.
            mutation.audit_options[:timing_string] = injected

            mutation.altered_value = injected.
                gsub( '__TIME__', (opts[:delay] / opts[:timeout_divider]).to_s )
        end

        opts.merge!( each_mutation: each_mutation, skip_original: true )

        audit( payloads, opts ) do |res, elem|
            next if !block || res.app_time < (opts[:delay] + opts[:add]) / 1000.0

            block.call( elem )
        end
    end

end
end
end
