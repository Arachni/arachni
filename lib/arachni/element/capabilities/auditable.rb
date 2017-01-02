=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'with_auditor'

module Arachni
module Element::Capabilities

# Provides inputs, HTTP submission and audit functionality to
# {Arachni::Element::Capabilities::Mutable} elements.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Auditable
    include Utilities
    include WithAuditor

    # Load and include all available analysis/audit techniques.
    Dir.glob( File.dirname( __FILE__ ) + '/auditable/**/*.rb' ).each { |f| require f }

    # @return      [Hash]
    #   Audit and general options for convenience's sake.
    attr_accessor :audit_options

    # Default audit options.
    OPTIONS = {
        # Optionally enable skipping of already audited inputs, disabled by default.
        redundant:     false,

        # Block to be passed each mutation right before being submitted.
        # Allows for last minute changes.
        each_mutation: nil,

        # Block to be passed each mutation to determine if it should be skipped.
        skip_like:     nil
    }

    # Empties the de-duplication/uniqueness look-up table.
    #
    # Unless you're sure you need this, set the :redundant flag to true when
    # calling audit methods to bypass it.
    def Auditable.reset
        State.audit.clear
        @@skip_like_blocks = []
    end
    reset

    # @param    [Block] block
    #   Block to decide whether an element should be skipped or not.
    #
    # @return   [Auditable] `self`
    def self.skip_like( &block )
        fail 'Missing block.' if !block_given?
        skip_like_blocks << block
        self
    end

    def initialize( options )
        super
        @audit_options = {}
    end

    # Resets the audit options to their original values.
    def reset
        super if defined?( super )
        @audit_options = {}
        self
    end

    # @note Requires an {#auditor}.
    #
    # Submits mutations of `self` and calls the `block` to handle the results.
    #
    # @param  [String, Array<String>, Hash{Symbol => <String, Array<String>>}]  payloads
    #   Payloads to inject, if given:
    #
    #   * {String} -- Will inject the single payload.
    #   * {Array} -- Will iterate over all payloads and inject them.
    #   * {Hash} -- Expects platform names (as `Symbol`s ) for keys and
    #       {Array} of `payloads` for values. The applicable `payloads` will be
    #       {Platform::Manager#pick picked} from the hash based on
    #       {#platforms applicable platforms} for the {#action resource} to be
    #       audited.
    # @param  [Hash]    opts
    #   Options as described in {OPTIONS}.
    # @param  [Block]   block
    #   Block to be used for analysis of responses, will be passed each
    #   {HTTP::Response response} and mutation.
    #
    # @return   [Boolean, nil]
    #
    #   * `true` when the audit was successful.
    #   * `false` when:
    #       * There are no {#inputs} inputs.
    #       * The element is {WithScope::Scope#out? out} of {WithScope::Scope}.
    #       * The element has already been audited and the `:redundant` option
    #          is `false` -- the default.
    #       * The element matches a {.skip_like} block.
    #   * `nil` when:
    #       * An empty array/hash of `payloads` was given.
    #       * There are no `payloads` applicable to the element's platforms.
    #
    # @raise    ArgumentError
    #   On unsupported `payloads` type.
    #
    # @see #submit
    def audit( payloads, opts = {}, &block )
        return false if self.inputs.empty?

        if scope.out?
            print_debug_level_2 "Element is out of scope, skipping: #{audit_id}"
            return false
        end

        case payloads
            when String
                audit_single( payloads, opts, &block )

            when Array
                return if payloads.empty?

                payloads.each do |payload|
                    audit_single( payload, opts, &block )
                end

            when Hash
                platform_payloads = platforms.any? ?
                    platforms.pick( payloads ) : payloads

                return if platform_payloads.empty?

                payload_platforms = Set.new( payloads.keys )
                platform_payloads.each do |platform, payloads_for_platform|
                    audit( [payloads_for_platform].flatten.compact,
                           opts.merge(
                               platform: platform,
                               payload_platforms: payload_platforms
                           ),
                           &block )
                end

            else
                raise ArgumentError,
                      "Unsupported payload type '#{payloads.class}'. " <<
                          'Expected one of: String, Array, Hash'
        end
    end

    # @note To be overridden by inputs element implementations for more
    #   fine-grained audit control.
    #
    # @return   [Boolean]
    #   `true` if `self` should be audited, `false` otherwise.
    #
    # @abstract
    def skip?( elem )
        false
    end

    # @return  [String]
    #   Status message explaining what input vector is being audited, containing
    #   its name, {Element::Base#type} and {#action}.
    def audit_status_message
        "Auditing #{self.type} input '#{affected_input_name}'" <<
            " pointing to: '#{audit_status_message_action}'"
    end

    # Action URL to be used in {#audit_status_message} instead of
    # {Submittable#action}.
    #
    # @abstract
    def audit_status_message_action
        self.action
    end

    # @return  [String]
    #   Verbose message including the payload used to audit the current vector.
    def audit_verbose_message
        s = "With: #{seed.inspect}"

        if seed != affected_input_value
            s << " -> #{affected_input_value.inspect}"
        end

        s
    end

    # @param  [String]  payload
    #   Payload about to be used for the {#audit}.
    #
    # @return  [String]
    #   ID string used to identify the {#audit} of `self` by its {#auditor}.
    def audit_id( payload = nil )
        "#{auditor.class.name}:#{coverage_id}:#{payload}"
    end

    # @note Differences in input values will not be taken into consideration.
    #
    # @return  [String]
    #   String identifying self's coverage of the web application's input surface.
    def coverage_id
        "#{action}:#{type}:#{inputs.keys.sort}"
    end

    # @return  [Integer]
    #   Digest of {#coverage_id}.
    def coverage_hash
        coverage_id.persistent_hash
    end

    # @return [Boolean]
    #   `true` if the element matches one or more {.skip_like_blocks},
    #   `false` otherwise.
    #
    # @see .skip_like_blocks
    def matches_skip_like_blocks?
        Auditable.matches_skip_like_blocks? self
    end

    def dup
        copy_auditable( super )
    end

    protected

    # Calls {#submit} and does some internal processing (prints messages etc.)
    # before forwarding the response and performer element to the `block`.
    #
    # @param  [Block]   block
    #   Block to be used for analysis of the response.
    def submit_and_process( &block )
        submit( @audit_options[:submit] || {} ) do |response|
            # In case of redirection or runtime scope changes.
            if !response.parsed_url.seed_in_host? && response.scope.out?
                next
            end

            element = response.request.performer
            if !element.audit_options[:silent]
                print_status "Analyzing response ##{response.request.id} for " <<
                    "#{self.type} input '#{affected_input_name}'" <<
                    " pointing to: '#{audit_status_message_action}'"
            end

            exception_jail( false ){ block.call( response, element ) }
        end
    end

    private

    def copy_auditable( other )
        other.audit_options = self.audit_options.dup
        other
    end

    # @note Requires an {#auditor}.
    #
    # Submits mutations of self and calls the block to handle the responses.
    #
    # @param  [String]  payload
    #   The string to be injected.
    # @param  [Hash]    opts
    #   Options as described in {OPTIONS}.
    # @param  [Block]   block
    #   Block to be used for analysis of responses, will be passed each
    #   {HTTP::Response response} and mutation.
    #
    # @return   [Boolean]
    #   `true` if the audit was successful, `false` if:
    #
    #    * The `payload` contains {Inputtable#valid_input_data? invalid} data
    #       for this element type.
    #    * There are no {#inputs} inputs.
    #    * The element is {WithScope::Scope#out? out} of {WithScope::Scope}.
    #    * The element has already been audited and the `:redundant` option
    #       is `false` -- the default.
    #    * The element matches a {.skip_like} block.
    #
    # @see #submit
    def audit_single( payload, opts = { }, &block )

        if !valid_input_data?( payload )
            print_debug_level_2 "Payload not supported by #{self}: #{payload.inspect}"
            return false
        end

        @audit_options = OPTIONS.merge( opts )

        print_debug_level_2 "About to audit: #{audit_id}"

        self.auditor ||= @audit_options.delete( :auditor )

        caudit_id = audit_id( payload )
        if !@audit_options[:redundant] && audited?( caudit_id )
            print_debug_level_2 "Skipping, already audited: #{caudit_id}"
            return false
        end
        audited caudit_id

        if matches_skip_like_blocks?
            print_debug_level_2 'Element matches one or more skip_like blocks, skipping.'
            return false
        end

        print_debug_level_2 "Payload platform: #{@audit_options[:platform]}" if opts.include?( :platform )

        # Options will eventually be serialized so remove non-serializeable
        # objects. Also, blocks are expensive, they should not be kept in the
        # options otherwise they won't be GC'ed.
        skip_like_option = [@audit_options.delete(:skip_like)].flatten.compact
        each_mutation    = @audit_options.delete(:each_mutation)

        # Iterate over all fuzz variations and audit each one.
        each_mutation( payload, @audit_options ) do |elem|
            if !audit_input?( elem.affected_input_name )
                print_info "Skipping audit of out of scope '#{elem.affected_input_name}' #{type} input vector."
                next
            end

            if elem.matches_skip_like_blocks?
                print_debug_level_2 'Element matches one or more skip_like blocks, skipping.'
                next
            end

            if !orphan? && auditor.skip?( elem )
                mid = elem.audit_id( payload )
                print_debug_level_2 "Auditor's #skip? method returned true for mutation, skipping: #{mid}"
                next
            end

            if skip?( elem )
                mid = elem.audit_id( payload  )
                print_debug_level_2 "Self's #skip? method returned true for mutation, skipping: #{mid}"
                next
            end

            if skip_like_option.any?
                should_skip = false
                skip_like_option.each do |like|
                    if like.call( elem )
                        mid = elem.audit_id( payload  )
                        print_debug_level_2 ":skip_like callbacks returned true for mutation, skipping: #{mid}"
                        print_debug_level_2 "--> #{like}"
                        break should_skip = true
                    end
                end

                next if should_skip
            end

            if !@audit_options[:silent]
                print_status elem.audit_status_message
                print_verbose "--> #{elem.audit_verbose_message}"
            end

            # Process each mutation via the supplied block, if we have one, and
            # submit new mutations returned by that block, if any.
            if each_mutation && (elements = each_mutation.call( elem ))
                [elements].flatten.compact.each do |e|
                    next if !e.is_a?( self.class )

                    e.submit_and_process( &block )
                end
            end

            elem.submit_and_process( &block )
        end

        true
    end

    def audit_input?( name )
        Options.audit.vector?( name )
    end

    # Checks whether or not an audit has been already performed.
    #
    # @param  [String]  elem_audit_id
    #   A string returned by {#audit_id}.
    #
    # @see #audited
    def audited?( elem_audit_id )
        State.audit.include?( elem_audit_id )
    end

    # Registers an audited element to avoid duplicate audits.
    #
    # @param  [String]  audit_id
    #   {#audit_id Audit ID}.
    #
    # @see #audited?
    def audited( audit_id )
        State.audit << audit_id
    end

    def self.skip_like_blocks
        @@skip_like_blocks
    end

    def self.matches_skip_like_blocks?( element )
        skip_like_blocks.each { |b| return true if b.call( element ) }
        false
    end

end

end
end
