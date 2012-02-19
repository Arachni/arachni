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


module Arachni::Parser::Element::Analysis::Timeout

    def self.included( mod )
        @@parent = mod

        #
        # Returns the names of all loaded modules that use timing attacks.
        #
        # @return   [Set]
        #
        def @@parent.timeout_loaded_modules
            @@__timeout_loaded_modules
        end

        #
        # Holds timing-attack performing Procs to be run after all
        # non-timing-attack modules have finished.
        #
        # @return   [Queue]
        #
        def @@parent.timeout_audit_blocks
            @@__timeout_audit_blocks
        end

        def @@parent.current_timeout_audit_operations_cnt
            @@__timeout_audit_blocks.size + @@__timeout_candidates.size
        end

        def @@parent.add_timeout_audit_block( &block )
            @@__timeout_audit_operations_cnt += 1
            @@__timeout_audit_blocks << block
        end

        def @@parent.add_timeout_candidate( elem )
            @@__timeout_audit_operations_cnt += 1
            @@__timeout_candidates << elem
        end


        def @@parent.running_timeout_attacks?
            @@__running_timeout_attacks
        end

        def @@parent.on_timing_attacks( &block )
            @@__on_timing_attacks << block
        end

        def @@parent.timeout_audit_operations_cnt
            @@__timeout_audit_operations_cnt
        end

        def @@parent.call_on_timing_blocks( res, elem )
            @@__on_timing_attacks.each {
                |block|
                block.call( res, elem )
            }
        end

        #
        # Runs all blocks in {timeout_audit_blocks} and verifies
        # and logs the candidate elements.
        #
        def @@parent.timeout_audit_run
            @@__running_timeout_attacks = true

            while( !@@__timeout_audit_blocks.empty? )
                @@__timeout_audit_blocks.pop.call
            end

            while( !@@__timeout_candidates.empty? )
                self.audit_timeout_phase_2( @@__timeout_candidates.pop )
            end
        end

        #
        # Runs phase 2 of the timing attack auditing an individual element
        # (which passed phase 1) with a higher delay and timeout
        #
        def @@parent.audit_timeout_phase_2( elem )

            # reset the audited list since we're going to re-audit the elements
            # @@__timeout_audited = Set.new

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
            elem.auditor.http.get( elem.action ).on_complete {
                |res|

                # ap elem.auditable
                # ap res.effective_url
                # ap res.request.params

                self.call_on_timing_blocks( res, elem )

                if !res.timed_out?

                    elem.auditor.print_info( 'Liveness check was successful, progressing to verification...' )

                    elem.audit( str, opts ) {
                        |c_res, c_opts|

                        # ap c_res.time
                        # ap opts[:timeout]

                        if c_res.timed_out?

                            # all issues logged by timing attacks need manual verification.
                            # end of story.
                            # c_opts[:verification] = true
                            elem.auditor.log( c_opts, c_res )

                            self.audit_timeout_stabilize( elem )

                        else
                            elem.auditor.print_info( 'Verification failed.' )
                        end
                    }
                else
                    elem.auditor.print_info( 'Liveness check failed, bailing out...' )
                end
            }

            elem.auditor.http.run
        end

        #
        # Submits an element which has just been audited using a timing attack
        # with a high timeout in order to determine when the effects of a timing
        # attack has worn off in order to safely continue the audit.
        #
        # @param    [Arachni::Element::Auditable]   elem
        #
        def @@parent.audit_timeout_stabilize( elem )

            d_opts = {
                :skip_orig => true,
                :redundant => true,
                :timeout   => 120000,
                :silent    => true,
                :async     => false
            }

            orig_opts = elem.opts

            elem.auditor.print_info( 'Waiting for the effects of the timing attack to wear off.' )
            elem.auditor.print_info( 'Max waiting time: ' + ( d_opts[:timeout] /1000 ).to_s + ' seconds.' )

            elem.auditable = elem.orig
            res = elem.submit( d_opts ).response

            if !res.timed_out?
                elem.auditor.print_info( 'Server seems responsive again.' )
            else
                elem.auditor.print_error( 'Max waiting time exceeded, the server may be dead.' )
            end

            elem.opts.merge!( orig_opts )
        end


        def call_on_timing_blocks( res, elem )
            @@parent.call_on_timing_blocks( res, elem )
        end


        # @@__timeout_audited      ||= Set.new

        # holds timing-attack performing Procs to be run after all
        # non-timing-attack modules have finished.
        @@__timeout_audit_blocks   ||= Queue.new

        @@__timeout_audit_operations_cnt ||= 0

        # populated by timing attack phase 1 with
        # candidate elements to be verified by phase 2
        @@__timeout_candidates     ||= Queue.new

        # modules which have called the timing attack audit method (audit_timeout)
        # we're interested in the amount, not the names, and is used to
        # determine scan progress
        @@__timeout_loaded_modules ||= Set.new

        @@__on_timing_attacks      ||= []

        @@__running_timeout_attacks ||= false

        # # the rdiff attack performs it own redundancy checks so we need this to
        # # keep track audited elements
        # @@__rdiff_audited ||= Set.new
    end

    # #
    # # Returns the names of all loaded modules that use timing attacks.
    # #
    # # @return   [Set]
    # #
    # def @@parent.timeout_loaded_modules
        # @@__timeout_loaded_modules
    # end
#
    # #
    # # Holds timing-attack performing Procs to be run after all
    # # non-timing-attack modules have finished.
    # #
    # # @return   [Queue]
    # #
    # def @@parent.timeout_audit_blocks
        # @@__timeout_audit_blocks
    # end
#
    # def @@parent.current_timeout_audit_operations_cnt
        # @@__timeout_audit_blocks.size + @@__timeout_candidates.size
    # end
#
    # def @@parent.add_timeout_audit_block( &block )
        # @@__timeout_audit_operations_cnt += 1
        # @@__timeout_audit_blocks << block
    # end
#
    # def @@parent.add_timeout_candidate( elem )
        # @@__timeout_audit_operations_cnt += 1
        # @@__timeout_candidates << elem
    # end
#
#
    # def @@parent.running_timeout_attacks?
        # @@__running_timeout_attacks
    # end
#
    # def @@parent.on_timing_attacks( &block )
        # @@__on_timing_attacks << block
    # end
#
    # def @@parent.timeout_audit_operations_cnt
        # @@__timeout_audit_operations_cnt
    # end
#
    # def @@parent.call_on_timing_blocks( res, elem )
        # @@__on_timing_attacks.each {
            # |block|
            # block.call( res, elem )
        # }
    # end
#
    # def call_on_timing_blocks( res, elem )
        # @@parent.call_on_timing_blocks( res, elem )
    # end
#
    #
    # Audits elements using timing attacks and automatically logs results.
    #
    # Here's how it works:
    # * Loop 1 -- Populates the candidate queue. We're picking the low hanging
    #   fruit here so we can run this in larger concurrent bursts which cause *lots* of noise.
    #   - Initial probing for candidates -- Any element that times out is added to a queue.
    #   - Stabilization -- The candidate is submitted with its default values in
    #     order to wait until the effects of the timing attack have worn off.
    # * Loop 2 -- Verifies the candidates. This is much more delicate so the
    #   concurrent requests are lowered to pairs.
    #   - Liveness test -- Ensures that stabilization was successful before moving on.
    #   - Verification using an increased timeout -- Any elements that time out again are logged.
    #   - Stabilization
    #
    # Ideally, all requests involved with timing attacks would be run in sync mode
    # but the performance penalties are too high, thus we compromise and make the best of it
    # by running as little an amount of concurrent requests as possible for any given phase.
    #
    #    opts = {
    #        :format  => [ Format::STRAIGHT ],
    #        :timeout => 4000,
    #        :timeout_divider => 1000
    #    }
    #
    #    audit_timeout( [ 'sleep( __TIME__ );' ], opts )
    #
    #
    # @param   [Array]     strings     injection strings
    #                                       __TIME__ will be substituted with (timeout / timeout_divider)
    # @param  [Hash]        opts        options as described in {OPTIONS} with the following extra:
    #                                   * :timeout -- milliseconds to wait for the request to complete
    #                                   * :timeout_divider -- __TIME__ = timeout / timeout_divider
    #
    def timeout_analysis( strings, opts )
        @@__timeout_loaded_modules << @auditor.class.info[:name]

        @@parent.add_timeout_audit_block {
            delay = opts[:timeout]

            audit_timeout_debug_msg( 1, delay )
            timing_attack( strings, opts ) {
                |res, c_opts, elem|

                elem.auditor = @auditor

                @auditor.print_info( "Found a candidate -- #{elem.type.capitalize} input '#{elem.altered}' at #{elem.action}" )

                @@parent.audit_timeout_stabilize( elem )
                @@parent.add_timeout_candidate( elem )
            }
        }
    end

    def audit_timeout_debug_msg( phase, delay )
        print_debug( '---------------------------------------------' )
        print_debug( "Running phase #{phase.to_s} of timing attack." )
        print_debug( "Delay set to: #{delay.to_s} milliseconds" )
        print_debug( '---------------------------------------------' )
    end

    #
    # Audits elements using a timing attack.
    #
    # 'opts' needs to contain a :timeout value in milliseconds.</br>
    # Optionally, you can add a :timeout_divider.
    #
    # @param   [Array]     strings     injection strings
    #                                       '__TIME__' will be substituted with (timeout / timeout_divider)
    # @param    [Hash]      opts        options as described in {OPTIONS}
    # @param    [Block]     &block      block to call if a timeout occurs,
    #                                       it will be passed the response and opts
    #
    def timing_attack( strings, opts, &block )

        opts[:timeout_divider] ||= 1

        [strings].flatten.each {
            |str|

            opts[:timing_string] = str
            str = str.gsub( '__TIME__', ( (opts[:timeout] + 3 * opts[:timeout_divider]) / opts[:timeout_divider] ).to_s )
            opts[:skip_orig] = true

            audit( str, opts ) {
                |res, c_opts, elem|
                call_on_timing_blocks( res, elem )

                block.call( res, c_opts, elem ) if block && res.timed_out?
            }
        }

        @auditor.http.run
    end

end
