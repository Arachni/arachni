=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
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
    #         pairs: [
    #               { 'true expression' => 'false expression' }
    #         ]
    #     }
    #
    #     element.rdiff_analysis( opts )
    #
    # Here's how it goes:
    #
    # * let `control` be the control/control response
    # * let `true_response`   be the response of the injection of 'true expression'
    # * let `false_response`    be the response of the injection of 'false expression'
    #
    # A vulnerability is logged if:
    #
    #     control == true_response AND true_response.code == 200 AND false_response != true_response
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

        return false if auditable.empty?

        # Don't continue if there's a missing value.
        auditable.values.each { |val| return if val.to_s.empty? }

        return false if rdiff_audited?
        rdiff_audited

        responses = {}
        control  = nil
        opts[:precision].times do
            # Get the default response.
            submit do |res|
                if control
                    print_status 'Got default/control response.'
                end

                # Remove context-irrelevant dynamic content like banners and such.
                control = (control ? control.rdiff( res.body ) : res.body)
            end
        end

        opts[:pairs].each do |pair|
            responses[pair] ||= {}
            true_expr, false_expr = pair.to_a.first

            opts[:precision].times do
                mutations( true_expr, opts ).each do |elem|
                    print_status elem.status_string

                    # Submit the mutation and store the response.
                    elem.submit( opts ) do |res|
                        if responses[pair][elem.altered][:true]
                            elem.print_status "Gathering data for '#{elem.altered}' " <<
                                                  "#{type} input -- Got true  response:" <<
                                                  " #{true_expr}"
                        end

                        responses[pair][elem.altered] ||= {}
                        responses[pair][elem.altered][:mutation] = elem

                        # Keep the latest response for the {Arachni::Issue}.
                        responses[pair][elem.altered][:response]        = res
                        responses[pair][elem.altered][:injected_string] = true_expr

                        responses[pair][elem.altered][:true] ||= res.body.clone
                        # Remove context-irrelevant dynamic content like banners
                        # and such from the error page.
                        responses[pair][elem.altered][:true] =
                            responses[pair][elem.altered][:true].rdiff( res.body.clone )
                    end
                end

                mutations( false_expr, opts ).each do |elem|
                    responses[pair][elem.altered] ||= {}

                    # Submit the mutation and store the response.
                    elem.submit( opts ) do |res|
                        if responses[pair][elem.altered][:false]
                            elem.print_status "Gathering data for '#{elem.altered}'" <<
                                                  " #{type} input -- Got false " <<
                                                  "response: #{false_expr}"
                        end

                        responses[pair][elem.altered][:false] ||= res.body.clone

                        # Remove context-irrelevant dynamic content like banners
                        # and such from the error page.
                        responses[pair][elem.altered][:false] =
                            responses[pair][elem.altered][:false].rdiff( res.body.clone )
                    end
                end
            end
        end


        # When this runs the "responses" hash will have been populated and we
        # can continue with analysis.
        http.after_run do
            responses.each do |pair, data|
                if block
                    exception_jail( false ){ block.call( pair, data ) }
                    next
                end

                data.each do |input_name, result|
                    # if default_response_body == true_response_body AND
                    #    false_response_body != true_response_code AND
                    #    true_response_code == 200
                    if control == result[:true] &&
                        result[:false] != result[:true] &&
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
        @action + @auditable.keys.to_s
    end

end
end
end
