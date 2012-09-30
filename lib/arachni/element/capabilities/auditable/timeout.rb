=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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

require 'set'

module Arachni::Element::Capabilities

#
# Evaluates whether or not the injection of specific data affects the response
# time of the web application.
#
# It takes into account unstable network conditions and server-side failures and
# verifies the results before logging.
#
# == Methodology
#
# Here's how it works:
# * Loop 1 ({#timeout_analysis}) -- Populates the candidate queue. We're picking the low hanging
#   fruit here so we can run this in larger concurrent bursts which cause *lots* of noise.
#   - Initial probing for candidates -- If element times out it is added to a queue.
#   - Stabilization ({#responsive?}) -- The element is submitted with its default values in
#     order to wait until the effects of the timing attack have worn off.
# * Loop 2 ({timeout_analysis_phase_2}) -- Verifies the candidates. This is much more delicate so the
#   concurrent requests are lowered to pairs.
#   - Liveness test -- Ensures that the webapp is alive and not just timing-out by default
#   - Verification using an increased timeout delay -- Any elements that time out again are logged.
#   - Stabilization ({#responsive?})
#
# Ideally, all requests involved with timing attacks would be run in sync mode
# but the performance penalties are too high, thus we compromise and make the best of it
# by running as little an amount of concurrent requests as possible for any given phase.
#
# == Usage
#
# Call {#timeout_analysis} to schedule a timeout audit and execute {timeout_audit_run}
# to run the scheduled operations.
#
# This deviates from the normal framework structure because it is preferable
# to run timeout audits separately in order to avoid interference by other
# audit operations.
#
# If you want to be notified every time a timeout audit is performed you can pass
# callback block to {on_timing_attacks}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Auditable::Timeout

    def self.included( mod )
        @@parent = mod

        #
        # Returns the names of all loaded modules that use timing attacks.
        #
        # @return   [Set]
        #
        def @@parent.timeout_loaded_modules
            @@timeout_loaded_modules
        end

        #
        # Holds timing-attack performing Procs to be run after all
        # non-timing-attack modules have finished.
        #
        # @return   [Queue]
        #
        def @@parent.timeout_audit_blocks
            @@timeout_audit_blocks
        end

        #
        # @return   [Integer]    amount of timeout-audit related operations
        #                           (audit blocks + candidate elements)
        #
        def @@parent.current_timeout_audit_operations_cnt
            @@timeout_audit_blocks.size + @@timeout_candidates.size
        end

        def @@parent.add_timeout_audit_block( &block )
            @@timeout_audit_operations_cnt += 1
            @@timeout_audit_blocks << block
        end

        def @@parent.add_timeout_candidate( elem )
            @@timeout_audit_operations_cnt += 1
            @@timeout_candidates << elem
        end

        #
        # @return   [Bool]  true if timeout attacks are currently running
        #
        def @@parent.running_timeout_attacks?
            @@running_timeout_attacks
        end

        #
        # Adds a block to be executed every time a timing attack is performed
        #
        def @@parent.on_timing_attacks( &block )
            @@on_timing_attacks << block
        end

        #
        # @return   [Integer]    amount of timeout-audit operations
        #
        def @@parent.timeout_audit_operations_cnt
            @@timeout_audit_operations_cnt
        end

        def @@parent.call_on_timing_blocks( res, elem )
            @@on_timing_attacks.each { |block| block.call( res, elem ) }
        end

        #
        # Runs all blocks in {timeout_audit_blocks} and verifies
        # and logs the candidate elements.
        #
        def @@parent.timeout_audit_run
            @@running_timeout_attacks = true

            while !@@timeout_audit_blocks.empty?
                @@timeout_audit_blocks.pop.call
            end

            while !@@timeout_candidates.empty?
                self.timeout_analysis_phase_2( @@timeout_candidates.pop )
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

            # reset the audited list since we're going to re-audit the elements
            # @@timeout_audited = Set.new

            opts = elem.opts
            opts[:timeout] *= 2
            # opts[:async]    = false
            # self.audit_timeout_debug_msg( 2, opts[:timeout] )

            str = opts[:timing_string].gsub( '__TIME__',
                ( opts[:timeout] / opts[:timeout_divider] ).to_s )

            opts[:timeout] *= 0.7

            elem.auditable = elem.orig

            # this is the control; request the URL of the element to make sure
            # that the web page is alive i.e won't time-out by default
            elem.submit do |res|
                self.call_on_timing_blocks( res, elem )

                if res.timed_out?
                    elem.print_info 'Liveness check failed, bailing out...'
                    next
                end

                elem.print_info 'Liveness check was successful, progressing to verification...'
                elem.audit( str, opts ) do |c_res, c_opts|
                    if !c_res.timed_out?
                        elem.print_info 'Verification failed.'
                        next
                    end

                    # all issues logged by timing attacks need manual verification.
                    # end of story.
                    # c_opts[:verification] = true
                    elem.auditor.log( c_opts, c_res )
                    elem.responsive?
                end

            end

            elem.http.run
        end

        def call_on_timing_blocks( res, elem )
            @@parent.call_on_timing_blocks( res, elem )
        end

        # holds timing-attack performing Procs to be run after all
        # non-timing-attack modules have finished.
        @@timeout_audit_blocks   ||= Queue.new

        @@timeout_audit_operations_cnt ||= 0

        # populated by timing attack phase 1 with
        # candidate elements to be verified by phase 2
        @@timeout_candidates     ||= Queue.new

        # modules which have called the timing attack audit method (audit_timeout)
        # we're interested in the amount, not the names, and is used to
        # determine scan progress
        @@timeout_loaded_modules ||= Set.new

        @@on_timing_attacks      ||= []

        @@running_timeout_attacks ||= false
    end

    #
    # Performs timeout/time-delay analysis and logs an issue should there be one.
    #
    # @param   [Array]     strings     injection strings
    #                                       __TIME__ will be substituted with (timeout / timeout_divider)
    # @param   [Hash]      opts        options as described in {Arachni::Element::Mutable::OPTIONS} with the following extra:
    #                                   * :timeout -- milliseconds to wait for the request to complete
    #                                   * :timeout_divider -- __TIME__ = timeout / timeout_divider
    #
    def timeout_analysis( strings, opts )
        @@timeout_loaded_modules << @auditor.fancy_name

        @@parent.add_timeout_audit_block {
            delay = opts[:timeout]

            audit_timeout_debug_msg( 1, delay )
            timing_attack( strings, opts ) do |_, _, elem|
                elem.auditor = @auditor

                print_info "Found a candidate -- #{elem.type.capitalize} input '#{elem.altered}' at #{elem.action}"

                @@parent.add_timeout_candidate( elem ) if elem.responsive?
            end
        }
    end

    #
    # Submits self with a high timeout value and blocks until it gets a response.
    #
    # That is to make sure that responsiveness has been restored before progressing further.
    #
    # @param    [Float] limit   how much time to afford the server to respond
    #
    # @return   [Bool] +true+ if server responds within the given time limit, +false+ otherwise
    #
    def responsive?( limit = 120.0 )
        d_opts = {
            skip_orig: true,
            redundant: true,
            timeout:   limit * 1000,
            silent:    true,
            async:     false
        }

        orig_opts = opts

        print_info 'Waiting for the effects of the timing attack to wear off.'
        print_info "Max waiting time: #{limit} seconds."

        @auditable = @orig
        res = submit( d_opts ).response

        @opts.merge!( orig_opts )

        if !res.timed_out?
            print_info 'Server seems responsive again.'
        else
            print_error 'Max waiting time exceeded, the server may be dead.'
            return false
        end

        true
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
    # @param   [Array]     strings     injection strings
    #                                       '__TIME__' will be substituted with (timeout / timeout_divider)
    # @param    [Hash]      opts       options as described in {Arachni::Element::Mutable::OPTIONS}
    # @param    [Block]     block      block to call if a timeout occurs,
    #                                       it will be passed the response and opts
    #
    def timing_attack( strings, opts, &block )
        opts[:timeout_divider] ||= 1

        [strings].flatten.each do |str|

            opts[:timing_string] = str
            str = str.gsub( '__TIME__', ( opts[:timeout] / opts[:timeout_divider] ).to_s )
            opts[:skip_orig] = true

            audit( str, opts ) do |res, c_opts, elem|
                call_on_timing_blocks( res, elem )
                block.call( res, c_opts, elem ) if block && res.timed_out?
            end
        end

        @auditor.http.run
    end

end
end
