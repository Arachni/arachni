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
# * Phase 2 ({timeout_analysis_phase_2}) -- Verifies the candidates. This is much more delicate so the
#   concurrent requests are lowered to pairs.
#   - Liveness test -- Ensures that the webapp is alive and not just timing-out by default
#   - Verification using an increased timeout delay -- Any elements that time out again are logged.
#   - Stabilization ({#responsive?})
# * Phase 3 ({timeout_analysis_phase_3}) -- Same as phase 2 but with a higher
#   delay to ensure that false-positives are truly weeded out.
#
# Ideally, all requests involved with timing attacks would be run in sync mode
# but the performance penalties are too high, thus we compromise and make the best of it
# by running as little an amount of concurrent requests as possible for any given phase.
#
# # Usage
#
# * Call {#timeout_analysis} to schedule requests for Phase 1.
# * Call {Arachni::HTTP#run} to run the Phase 1 requests which will populate
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
# If you want to be notified every time a timeout audit is performed you can pass
# a callback block to {on_timing_attacks}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Timeout

    def self.included( mod )
        @@parent = mod

        # @return   [Set]
        #   Names of all loaded modules that use timing attacks.
        def @@parent.timeout_loaded_modules
            @@timeout_loaded_modules
        end

        def @@parent.timeout_candidates
            @@timeout_candidates
        end

        # @return   [Integer]
        #   Amount of timeout-audit related operations
        #   (`audit blocks + candidate elements`).
        def @@parent.current_timeout_audit_operations_cnt
            @@timeout_candidates.size + @@timeout_candidates_phase3.size
        end

        def @@parent.add_timeout_candidate( elem )
            @@timeout_audit_operations_cnt += 1
            @@timeout_candidates << elem
        end

        def @@parent.add_timeout_phase3_candidate( elem )
            @@timeout_audit_operations_cnt += 1
            @@timeout_candidates_phase3 << elem
        end

        # @return   [Bool]
        #   `true` if timeout attacks are currently running, `false` otherwise.
        def @@parent.running_timeout_attacks?
            @@running_timeout_attacks
        end

        # @param    [Block] block
        #   Block to be executed every time a timing attack is performed.
        def @@parent.on_timing_attacks( &block )
            @@on_timing_attacks << block
        end

        # @return   [Integer]    Amount of timeout-audit operations.
        def @@parent.timeout_audit_operations_cnt
            @@timeout_audit_operations_cnt
        end

        def @@parent.call_on_timing_blocks( res, elem )
            @@on_timing_attacks.each { |block| block.call( res, elem ) }
        end

        # Verifies and logs candidate elements.
        def @@parent.timeout_audit_run
            @@running_timeout_attacks = true

            while !@@timeout_candidates.empty?
                self.timeout_analysis_phase_2( @@timeout_candidates.pop )
            end

            while !@@timeout_candidates_phase3.empty?
                self.timeout_analysis_phase_3( @@timeout_candidates_phase3.pop )
            end
        end

        #
        # (Called by {timeout_audit_run}, do *NOT* call manually.)
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
        #
        def @@parent.timeout_analysis_phase_2( elem )
            opts = elem.opts
            previous_timeout = opts[:delay]
            injected_timeout = opts[:delay] *= 2

            str = opts[:timing_string].
                gsub( '__TIME__', (opts[:delay] / opts[:timeout_divider]).to_s )

            elem.auditable = elem.orig

            # This is the control; request the URL of the element to make sure
            # that the web page is responsive i.e won't time-out by default.
            elem.submit( timeout: previous_timeout ) do |res|
                self.call_on_timing_blocks( res, elem )

                # Remove the timeout option set by the liveness check in order
                # to now affect later requests.
                elem.opts.delete( :timeout )

                if res.timed_out?
                    elem.print_info 'Phase 2: Liveness check failed, bailing out...'
                    next
                end

                elem.print_info 'Phase 2: Liveness check was successful, progressing to verification...'

                opts[:skip_like] = proc { |m| m.altered != elem.altered }
                elem.audit( str, opts ) do |c_res|
                    if c_res.app_time <= opts[:delay] / Float(1000)
                        elem.print_info 'Phase 2: Verification failed.'
                        next
                    end

                    if deduplicate?
                        next if @@timeout_candidate_phase3_ids.include?( elem.audit_id )
                        @@timeout_candidate_phase3_ids << elem.audit_id
                    end

                    elem.opts[:delay] = injected_timeout

                    elem.print_info 'Phase 2: Candidate can progress to Phase 3 --' <<
                        " #{elem.type.capitalize} input '#{elem.altered}' at #{elem.action}"

                    @@parent.add_timeout_phase3_candidate( elem )
                end
            end

            elem.http.run
        end

        def @@parent.disable_deduplication
            @@deduplicate = 'f'
        end

        def @@parent.enable_deduplication
            @@deduplicate = 't'
        end

        def @@parent.deduplicate?
            @@deduplicate == 't'
        end

        def @@parent.timeout_analysis_phase_3( elem )
            opts = elem.opts
            opts[:delay] *= 2

            str = opts[:timing_string].
                gsub( '__TIME__', (opts[:delay] / opts[:timeout_divider]).to_s )

            elem.auditable = elem.orig

            # this is the control; request the URL of the element to make sure
            # that the web page is alive i.e won't time-out by default
            elem.submit do |res|
                self.call_on_timing_blocks( res, elem )

                if res.timed_out?
                    elem.print_info 'Phase 3: Liveness check failed, bailing out...'
                    next
                end

                elem.print_info 'Phase 3: Liveness check was successful, progressing to verification...'

                opts[:skip_like] = proc { |m| m.altered != elem.altered }
                elem.audit( str, opts ) do |c_res, c_opts|
                    if c_res.app_time <= opts[:delay] / Float(1000)
                        elem.print_info 'Phase 3: Verification failed.'
                        next
                    end

                    elem.auditor.log( c_opts, c_res )
                    elem.responsive?
                end

            end

            elem.http.run
        end

        def call_on_timing_blocks( res, elem )
            @@parent.call_on_timing_blocks( res, elem )
        end

        @@timeout_audit_operations_cnt ||= 0

        # Populated by timing attack phase 1 with candidate elements to be
        # verified by phase 2.
        @@timeout_candidates     ||= []
        @@timeout_candidate_ids  ||= ::Arachni::Support::LookUp::HashSet.new

        @@timeout_candidates_phase3    ||= []
        @@timeout_candidate_phase3_ids ||= ::Arachni::Support::LookUp::HashSet.new

        # Modules which have called the timing attack audit method
        # ({Arachni::Module::Auditor#audit_timeout}) we're interested in the
        # amount, not the names, and is used to determine scan progress.
        @@timeout_loaded_modules ||= Set.new

        @@on_timing_attacks      ||= []

        @@running_timeout_attacks ||= false

        @@deduplicate ||= 't'
    end

    def Timeout.reset
        @@timeout_audit_operations_cnt = 0

        @@timeout_candidates.clear
        @@timeout_candidate_ids.clear

        @@timeout_candidates_phase3.clear
        @@timeout_candidate_phase3_ids.clear

        @@timeout_loaded_modules.clear

        @@deduplicate = true
    end

    def disable_deduplication
        @@parent.disable_deduplication
    end

    def enable_deduplication
        @@parent.enable_deduplication
    end

    def deduplicate?
        @@parent.deduplicate?
    end

    #
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
    # @option   opts    [Integer] :timeout_divider
    #   `__TIME__ = timeout / timeout_divider`
    #
    # @return   [Bool]
    #   `true` if the audit was scheduled successfully, `false` otherwise (like
    #   if the resource is out of scope).
    #
    def timeout_analysis( payloads, opts )
        if skip_path? self.action
            print_debug "Element's action matches skip rule, bailing out."
            return false
        end

        @@timeout_loaded_modules << @auditor.fancy_name

        audit_timeout_debug_msg( 1, opts[:timeout] )
        timing_attack( payloads, opts ) do |elem|
            elem.auditor = @auditor

            if deduplicate?
                next if @@timeout_candidate_ids.include?( elem.audit_id )
                @@timeout_candidate_ids << elem.audit_id
            end

            print_info 'Found a candidate for Phase 2 -- ' <<
                "#{elem.type.capitalize} input '#{elem.altered}' at #{elem.action}"

            next if !responsive?( opts[:timeout] )
            @@parent.add_timeout_candidate( elem )
        end

        true
    end

    #
    # Submits self with a high timeout value and blocks until it gets a response.
    #
    # That is to make sure that responsiveness has been restored before progressing further.
    #
    # @param    [Integer] limit   How many milliseconds to afford the server to respond.
    #
    # @return   [Bool]
    #   `true` if server responds within the given time limit, `false` otherwise.
    #
    def responsive?( limit = 120_000 )
        d_opts = {
            skip_orig: true,
            redundant: true,
            timeout:   limit,
            silent:    true,
            async:     false
        }

        orig_opts = opts

        print_info 'Waiting for the effects of the timing attack to wear off.'
        print_info "Max waiting time: #{d_opts[:timeout] / 1000.0} seconds."

        @auditable = @orig
        res = submit( d_opts ).response

        @opts.merge!( orig_opts )

        if res.timed_out?
            print_bad 'Max waiting time exceeded.'
            false
        else
            print_info 'Server seems responsive again.'
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

    #
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
    #   {Typhoeus::Response response} and `opts`.
    #
    def timing_attack( payloads, opts, &block )
        opts = opts.dup
        opts[:delay] = opts.delete(:timeout)
        opts[:timeout_divider] ||= 1

        # Intercept each element mutation prior to it being submitted and replace
        # the '__TIME__' placeholder with the actual delay value.
        each_mutation = proc do |mutation|
            injected = mutation.altered_value

            # Preserve the original because it's going to be needed for the
            # verification phases.
            mutation.opts[:timing_string] = injected

            mutation.altered_value = injected.
                gsub( '__TIME__', (opts[:delay] / opts[:timeout_divider]).to_s )
        end

        opts.merge!( each_mutation: each_mutation, skip_orig: true )

        audit( payloads, opts ) do |res, _, elem|
            call_on_timing_blocks( res, elem )
            next if !block || res.app_time < opts[:delay] / Float(1000)

            block.call( elem )
        end
    end

end
end
end
