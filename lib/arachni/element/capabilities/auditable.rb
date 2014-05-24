=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'inputtable'
require_relative 'mutable'
require_relative 'submittable'
require_relative 'with_auditor'

module Arachni
module Element::Capabilities

# Provides inputs, HTTP submission and audit functionality to
# {Arachni::Element::Capabilities::Mutable} elements.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Auditable
    include Utilities
    include Inputtable
    include Submittable
    include Mutable
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
    #       * The {#action} matches a {#skip_path? skip} rule.
    #       * The element has already been audited and the `:redundant` option
    #          is `false` -- the default.
    #       * The element matches a {.skip_like} block.
    #   * `nil` when:
    #       * An empty array/hash of `payloads` was given.
    #       * There are no `payloads` applicable to the element's platforms.
    #
    # @raise    ArgumentError
    #   On missing `block` or unsupported `payloads` type.
    #
    # @see #submit
    def audit( payloads, opts = { }, &block )
        fail ArgumentError, 'Missing block.' if !block_given?

        return false if self.inputs.empty?

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
    #   Status string explaining what's being audited.
    #
    #   The string contains the name of the input that is being audited,
    #   the url and the type of the input (form, link, cookie...).
    def status_string
        "Auditing #{self.type} input '#{@affected_input_name}' with" <<
            " action '#{@action}'."
    end

    # @note Mostly used to keep track of what audits have been perform in order
    #   to prevent redundancies.
    #
    # Returns an audit ID string used to identify the audit of `self` by its
    # {#auditor}.
    #
    # @param  [String]  payload
    # @param  [Hash]    opts
    #
    # @return  [String]
    def audit_id( payload = nil, opts = {} )
        vars = inputs.keys.sort.to_s

        str = ''
        str << "#{auditor.class.name}:" if !opts[:no_auditor] && !orphan?

        str << "#{audit_id_action}:#{type}:#{vars}"
        str << "=#{payload}" if !opts[:no_payload]

        str
    end

    def audit_id_action
        @action
    end

    # @note Used when in multi-Instance mode, to generate a white-list of
    #   element IDs that are allowed to be audited.
    #
    # Provides a more generalized audit ID which does not take into account
    # the auditor's name.
    #
    # @param    [Hash]  opts
    #   {#audit} options.
    #
    # @return   [Integer]   Hash ID.
    def audit_scope_id( opts = {} )
        audit_id( nil, opts.merge( no_auditor: true, no_payload: true ) ).persistent_hash
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
    #    * The {Element::Base#action} matches a {#skip_path? skip} rule.
    #    * The element has already been audited and the `:redundant` option
    #       is `false` -- the default.
    #    * The element matches a {.skip_like} block.
    #
    # @raise    [ArgumentError]
    #   On missing `block`.
    #
    # @see #submit
    def audit_single( payload, opts = { }, &block )
        fail ArgumentError, 'Missing block.' if !block_given?

        if !valid_input_data?( payload )
            print_debug_level_2 "Payload not supported by #{self}: #{payload.inspect}"
            return false
        end

        @audit_options = OPTIONS.merge( opts )

        print_debug_level_2 "About to audit: #{audit_id}"

        # If we don't have any inputs elements just return.
        if inputs.empty?
            print_debug_level_2 'The element has no inputs inputs.'
            return false
        end

        if self.action && skip_path?( self.action )
            print_debug_level_2 "Element's action matches skip rule, bailing out."
            return false
        end

        self.auditor ||= @audit_options.delete( :auditor )

        audit_id = audit_id( payload, @audit_options )
        if !@audit_options[:redundant] && audited?( audit_id )
            print_debug_level_2 "Skipping, already audited: #{audit_id}"
            return false
        end
        audited audit_id

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

        submit_options = @audit_options[:submit] || {}

        # Iterate over all fuzz variations and audit each one.
        each_mutation( payload, @audit_options ) do |elem|
            if Options.audit.exclude_vectors.include?( elem.affected_input_name )
                print_info "Skipping audit of '#{elem.affected_input_name}' #{type} vector."
                next
            end

            if elem.matches_skip_like_blocks?
                print_debug_level_2 'Element matches one or more skip_like blocks, skipping.'
                next
            end

            if !orphan? && auditor.skip?( elem )
                mid = elem.audit_id( payload, @audit_options )
                print_debug_level_2 "Auditor's #skip? method returned true for mutation, skipping: #{mid}"
                next
            end

            if skip?( elem )
                mid = elem.audit_id( payload, @audit_options )
                print_debug_level_2 "Self's #skip? method returned true for mutation, skipping: #{mid}"
                next
            end

            if skip_like_option.any?
                should_skip = false
                skip_like_option.each do |like|
                    break should_skip = true if like.call( elem )
                end
                next if should_skip
            end

            # Inform the user about what we're auditing.
            print_status( elem.status_string ) if !@audit_options[:silent]

            # Process each mutation via the supplied block if we have one and
            # submit new mutations returned by that block, if any.
            if each_mutation && (elements = each_mutation.call( elem ))
                [elements].flatten.compact.each do |e|
                    next if !e.is_a?( self.class )
                    e.submit( submit_options ) { |response| on_complete( response, &block ) }
                end
            end

            # Submit the element with the injection values.
            elem.submit( submit_options ) { |response| on_complete( response, &block ) }
        end

        true
    end

    def skip_path?( url )
        super || redundant_path?( url )
    end

    # Registers a block to be executed as soon as the {Request} has been
    # completed and a {HTTP::Response} is available.
    #
    # @param  [Arachni::HTTP::Request]  request
    # @param  [Block]   block
    #   Block to be used for analysis of responses; will be passed the HTTP
    #   response as soon as it is received.
    def on_complete( request, &block )
        return if !request

        # If we're in blocking mode the passed object will be a response not
        # a request.
        if request.is_a? HTTP::Response
            after_complete( request, &block )
            return
        end

        request.on_complete { |response| after_complete( response, &block ) }
    end

    def after_complete( response, &block )
        element = response.request.performer
        if !element.audit_options[:silent]
            print_status "Analyzing response ##{response.request.id}..."
        end

        exception_jail( false ){ block.call( response, response.request.performer )}
    end

    # Checks whether or not an audit has been already performed.
    #
    # @param  [String]  elem_audit_id  a string returned by {#audit_id}
    #
    # @see #audited
    def audited?( elem_audit_id )
        State.audit.include?( elem_audit_id )
    end

    # Registers an audited element to avoid duplicate audits.
    #
    # @param  [String]  audit_id  {#audit_id Audit ID}.
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
