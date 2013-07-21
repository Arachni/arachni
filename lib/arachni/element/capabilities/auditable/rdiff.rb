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

#
# Performs boolean, fault injection and behavioral analysis (using the rDiff algorithm)
# in order to determine whether the web application is responding to the injected data and how.
#
# If the behavior can be manipulated by the injected data in ways that it's not supposed to
# (like when evaluating injected code) then the element is deemed vulnerable.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Auditable::RDiff

    def self.included( mod )
        # the rdiff attack performs it own redundancy checks so we need this to
        # keep track of audited elements
        @@rdiff_audited ||= Support::LookUp::HashSet.new
    end

    RDIFF_OPTIONS =  {
        # append our seeds to the default values
        format:    [Mutable::Format::APPEND],

        # allow duplicate requests
        redundant: true,

        # amount of rdiff iterations
        precision: 2,

        respect_method: true
    }

    #
    # Performs differential analysis and logs an issue should there be one.
    #
    #     opts = {
    #         :precision => 3,
    #         :faults    => [ 'fault injections' ],
    #         :bools     => [ 'boolean injections' ]
    #     }
    #
    #     element.rdiff_analysis( opts )
    #
    # Here's how it goes:
    #
    # * let `default` be the default/original response
    # * let `fault`   be the response of the fault injection
    # * let `bool`    be the response of the boolean injection
    #
    # A vulnerability is logged if:
    #
    #     default == bool AND bool.code == 200 AND fault != bool
    #
    # The `bool` response is also checked in order to determine if it's a custom
    # 404, if it is it'll be skipped.
    #
    # If a block has been provided analysis and logging will be delegated to it.
    #
    # @param    [Hash]  opts
    # @option   opts    [Integer]       :format
    #   As seen in {Arachni::Element::Capabilities::Mutable::Format}.
    # @option   opts    [Integer]       :precision
    #   Amount of {String#rdiff refinement} iterations to perform.
    # @option   opts    [Array<String>] :faults
    #   Array of fault injection strings (these are supposed to force erroneous
    #   conditions when interpreted).
    # @option   opts    [Array<String>] :bools
    #   Array of boolean injection strings (these are supposed to not alter the
    #   webapp behavior when interpreted).
    # @param    [Block]     block
    #   To be used for custom analysis of responses; will be passed the following:
    #
    #     * injected string
    #     * audited element
    #     * default response body
    #     * boolean response
    #     * fault injection response body
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

        # don't continue if there's a missing value
        inputs.values.each { |val| return if !val || val.empty? }

        return false if rdiff_audited?
        rdiff_audited

        responses = {
            # will hold the original, default, response that results from submitting
            original: nil,

            # will hold responses of boolean injections
            good: {},

            # will hold responses of fault injections
            bad:  {}
        }

        # submit the element, as is, opts[:precision] amount of times and
        # rdiff the responses in order to arrive to a refined response without
        # any superfluous dynamic content
        opts[:precision].times {
            # get the default responses
            audit( '', opts ) do |res|
                responses[:original] ||= res.body
                # remove context-irrelevant dynamic content like banners and such
                responses[:original] = responses[:original].rdiff( res.body )
            end
        }

        # perform fault injection opts[:precision] amount of times and
        # rdiff the responses in order to arrive to a refined response without
        # any superfluous dynamic content
        opts[:precision].times {
            opts[:faults].each do |str|
                # get mutations of self using the fault seed, which will
                # cause an internal/silent error when evaluated
                mutations( str, opts ).each do |elem|
                    print_status elem.status_string

                    # submit the mutation and store the response
                    elem.submit( opts ) do |res|
                        responses[:bad][elem.altered] ||= res.body.clone
                        # remove context-irrelevant dynamic content like banners and such
                        # from the error page
                        responses[:bad][elem.altered] =
                            responses[:bad][elem.altered].rdiff( res.body.clone )
                    end
                end
            end
        }

        # get injection variations that will not affect the outcome of the query
        opts[:bools].each do |str|

            # get mutations of self using the boolean seed, which will not
            # alter the execution flow
            mutations( str, opts ).each do |elem|
                print_status elem.status_string

                # submit the mutation and store the response
                elem.submit( opts ) do |res|
                    responses[:good][elem.altered] ||= []
                    # save the response and some data for analysis
                    responses[:good][elem.altered] << {
                        'str'  => str,
                        'res'  => res,
                        'elem' => elem
                    }
                end
            end
        end

        # when this runs the "responses" hash will have been populated and we
        # can continue with analysis
        http.after_run {

            responses[:good].keys.each do |key|
                responses[:good][key].each do |res|

                    # if there's a block passed then delegate analysis to it
                    if block
                        exception_jail( false ){
                            block.call( res['str'], res['elem'], responses[:original],
                                        res['res'], responses[:bad][key] )
                        }

                    # if default_response_body == bool_response_body AND
                    #    bool_response_code == 200 AND
                    #    fault_response_body != bool_response_body
                    elsif responses[:original] == res['res'].body &&
                            responses[:bad][key] != res['res'].body &&
                            res['res'].code == 200

                        # check to see if the current boolean response we're analyzing
                        # is a custom 404 page
                        http.custom_404?( res['res'] ) do |bool|
                            # if this is a custom 404 page bail out
                            next if bool

                            # if this isn't a custom 404 page then it means that
                            # the element is vulnerable, so go ahead and log the issue

                            # information for the Metareport report
                            opts = {
                                injected_orig: res['str'],
                                combo:         res['elem'].inputs
                            }

                            @auditor.log({
                                    var:      key,
                                    opts:     opts,
                                    injected: res['str'],
                                    id:       res['str'],
                                    elem:     res['elem'].type,
                                }, res['res']
                            )
                        end
                    end

                end
            end
        }

        true
    end

    private
    def rdiff_audited
        @@rdiff_audited << rdiff_audit_id
    end

    def rdiff_audited?
        @@rdiff_audited.include?( rdiff_audit_id )
    end

    def rdiff_audit_id
        @action + @inputs.keys.to_s
    end

end
end
end
