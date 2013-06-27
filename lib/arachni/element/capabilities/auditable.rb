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

lib = Options.dir['lib']
require lib + 'module/utilities'
require lib + 'issue'
require lib + 'element/capabilities/mutable'

module Element::Capabilities

#
# Provides audit functionality to {Arachni::Element::Mutable} elements.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Auditable
    include Utilities
    include Mutable

    # Load and include all available analysis/audit techniques.
    Dir.glob( File.dirname( __FILE__ ) + '/auditable/*.rb' ).each { |f| require f }

    include Taint
    include Timeout
    include RDiff

    #
    # Sets the auditor for this element.
    #
    # The auditor provides its output, HTTP and issue logging interfaces.
    #
    # @return   [Arachni::Module::Auditor]
    #
    attr_accessor :auditor

    #
    # Frozen version of {#auditable}, has all the original name/values.
    #
    # @return   [Hash]
    #
    attr_reader   :orig
    alias :original :orig

    #
    # @return [Hash]    Audit and general options for convenience's sake.
    #
    attr_reader   :opts

    #
    # Default audit options.
    #
    OPTIONS = {
        # Enable skipping of already audited inputs.
        redundant: false,

        # Make requests asynchronously.
        async:     true,

        #
        # Block to be passed each mutation right before being submitted.
        #
        # Allows for last minute changes.
        #
        each_mutation:  nil
    }

    #
    # Empties the de-duplication/uniqueness look-up table.
    #
    # Unless you're sure you need this, set the :redundant flag to true
    # when calling audit methods to bypass it.
    #
    def self.reset
        @@audited          = Support::LookUp::HashSet.new
        @@skip_like_blocks = []
    end
    reset

    # Removes workload restrictions and allows all elements to be audited.
    def self.reset_instance_scope
        @@restrict_to_elements = Support::LookUp::HashSet.new( hasher: :to_i )
    end
    reset_instance_scope

    #
    # Restricts the audit to a specific set of elements.
    #
    # *Caution*: Each call overwrites the last.
    #
    # @param    [Array<String,Integer>]    elements
    #   Element audit IDs as returned by {#scope_audit_id}.
    #
    # @see scope_audit_id
    #
    def self.restrict_to_elements( elements )
        self.reset_instance_scope
        elements.each { |elem| @@restrict_to_elements << elem }
    end

    # @param    [Block] block
    #   Block to decide whether an element should be skipped or not.
    #
    # @return   [Auditable] `self`
    def self.skip_like( &block )
        fail 'Missing block.' if !block_given?
        skip_like_blocks << block
        self
    end

    #
    # Assigns an anonymous auditor as an {#auditor}.
    #
    # Alleviates the need to assign a custom auditor for simple stuff when
    # scripting.
    #
    def use_anonymous_auditor
        self.auditor = Class.new do
            include Arachni::Module::Auditor

            def initialize
                @framework = Arachni::Framework.new
            end
            #
            # @return   [Array<Issue>]  Unfiltered logged issues.
            #
            # @see Arachni::Module::Manager.results
            #
            def raw_issues
                Arachni::Module::Manager.results
            end

            #
            # @return   [Array<Issue>]  Deduplicated issues.
            #
            # @see AuditStore#issues
            #
            def issues
                auditstore.issues
            end

            # @return   [AuditStore]
            def auditstore
                AuditStore.new( options: Options.instance.to_h,
                                issues:  raw_issues )
            end
            alias :audit_store :auditstore

            def self.info
                { name: 'Anonymous auditor' }
            end
        end.new
    end

    #
    # Frozen inputs.
    #
    # If you want to change it you'll either have to use {#update}
    # or the {#auditable=} attr_writer and pass a new hash -- the new hash
    # will also be frozen.
    #
    # @return   [Hash]
    #
    def auditable
        @auditable.freeze
    end

    #
    # @param  [Hash]  hash Inputs/params.
    #
    # @note Will convert keys and values to strings.
    #
    # @see #auditable
    #
    def auditable=( hash )
        @auditable = (hash || {}).inject({}) { |h, (k, v)| h[k.to_s] = v.to_s.freeze; h}
        rehash
        self.auditable
    end

    #
    # Checks whether or not the given inputs match the auditable ones.
    #
    # @param    [Hash, Array, String, Symbol]   args
    #   Names of inputs to check (also accepts var-args).
    #
    # @return   [Bool]
    #
    def has_inputs?( *args )
        if (h = args.first).is_a?( Hash )
            h.each { |k, v| return false if self[k] != v }
        else
            keys = args.flatten.compact.map { |a| [a].map( &:to_s ) }.flatten
            (self.auditable.keys & keys).size == keys.size
        end
    end

    #
    # @param    [Hash]  hash
    #   Inputs with which to update the {#auditable} inputs.
    #
    # @return   [Auditable]   self
    #
    # @see #auditable
    # @see #auditable=
    #
    def update( hash )
        self.auditable = self.auditable.merge( hash )
        self
    end

    # @return   [Hash]  Returns changes make to the {#auditable}'s inputs.
    def changes
        (self.orig.keys | self.auditable.keys).inject( {} ) do |h, k|
            if self.orig[k] != self.auditable[k]
                h[k] = self.auditable[k]
            end
            h
        end
    end

    #
    # Shorthand {#auditable} reader.
    #
    # @param    [#to_s] k   key
    #
    # @return   [String]
    #
    def []( k )
        self.auditable[k.to_s]
    end

    #
    # Shorthand {#auditable} writer.
    #
    # @param    [#to_s] k   key
    # @param    [#to_s] v   value
    #
    # @see #update
    #
    def []=( k, v )
        update( { k => v } )
        [k]
    end

    def ==( e )
        hash == e.hash
    end
    alias :eql? :==

    def hash
        @hash ||= rehash
    end

    #
    # When working in High Performance Grid mode the instances have
    # a very specific list of elements which they are allowed to audit.
    #
    # Elements which do not fit the scope are ignored.
    #
    # When called, the element will override the scope and be audited
    # no-matter what.
    #
    # This is mainly used on elements discovered during audit-time by the trainer.
    #
    def override_instance_scope
        @override_instance_scope = true
    end

    def reset_scope_override
        @override_instance_scope = false
    end

    #
    # Does this element override the instance scope?
    #
    # @see override_instance_scope
    #
    def override_instance_scope?
        @override_instance_scope ||= false
    end

    #
    # Provides a more generalized audit ID which does not take into account
    # the auditor's name nor timeout value of injection string.
    #
    # Right now only used when in multi-Instance mode to generate a white-list
    # of element IDs that are allowed to be audited.
    #
    # @param    [Hash]  opts    {#audit}    opts
    #
    # @return   [Integer]   Hash ID.
    #
    def scope_audit_id( opts = {} )
        opts = {} if !opts
        audit_id( nil, opts.merge(
            no_auditor:       true,
            no_timeout:       true,
            no_injection_str: true
        )).persistent_hash
    end

    #
    # Must be implemented by the including class and perform the appropriate
    # HTTP request (get/post/whatever) for the current element.
    #
    # Invoked by {#submit} to submit the object.
    #
    # @param    [Hash]      opts
    # @param    [Block]     block    Callback to be passed the HTTP response.
    #
    # @return   [Typhoeus::Request]
    #
    # @see #submit
    # @abstract
    #
    def http_request( opts, &block )
    end

    # @return   [Arachni::HTTP]
    def http
        HTTP
    end

    # @return   [Bool]  `true` if it has no auditor, `false` otherwise.
    def orphan?
        !@auditor
    end

    # Resets the auditable inputs to their original format/values.
    def reset
        self.auditable = @orig.dup
    end

    # Removes the {#auditor} from this element.
    def remove_auditor
        @auditor = nil
    end

    #
    # Submits self using {#http_request}.
    #
    # @param  [Hash]  opts
    # @param  [Block]  block    Callback to be passed the HTTP response.
    #
    # @see #http_request
    #
    def submit( opts = {}, &block )
        opts = OPTIONS.merge( opts )
        opts[:params]  = @auditable.dup
        opts[:follow_location] = true if !opts.include?( :follow_location )

        @opts ||= {}

        opts = @opts.merge( opts )
        @opts = opts

        @auditor ||= opts[:auditor] if opts[:auditor]
        use_anonymous_auditor if !@auditor

        opts.delete( :auditor )

        http_request( opts, &block )
    end

    #
    # Submits mutations of self and calls the block to handle the responses.
    #
    # @note Requires an {#auditor}, if none has been provided it will fallback
    #   to an {#use_anonymous_auditor anonymous} one.
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
    # @param  [Hash]    opts             Options as described in {OPTIONS}.
    # @param  [Block]   block
    #   Block to be used for analysis of responses; will be passed the following:
    #
    #   * {Typhoeus::Response HTTP response}.
    #   * Audit options, as a hash.
    #   * Vulnerable element mutation.
    #
    #   The `block` will be called as soon as the HTTP response is received.
    #
    # @return   [Boolean, nil]
    #
    #   * `true` when the audit was successful.
    #   * `false` when:
    #       * There are no {#auditable} inputs.
    #       * The {Element::Base#action} matches a {#skip_path? skip} rule.
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
    #
    def audit( payloads, opts = { }, &block )
        fail ArgumentError, 'Missing block.' if !block_given?

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

                platform_payloads.each do |platform, payloads_for_platform|
                    audit( [payloads_for_platform].flatten.compact,
                           opts.merge( platform: platform ),
                           &block )
                end
            else
                raise ArgumentError,
                      "Unsupported payload type '#{payloads.class}'. " <<
                          'Expected one of: String, Array, Hash'
        end
    end

    # @note To be overridden by auditable element implementations for more
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
    #
    def status_string
        "Auditing #{self.type} variable '#{self.altered}' with action '#{self.action}'."
    end

    #
    # Returns an audit ID string used to identify the audit of `self` by its
    # {#auditor}.
    #
    # @note Mostly used to keep track of what audits have been perform in order
    #   to prevent redundancies.
    #
    # @param  [String]  injection_str
    # @param  [Hash]    opts
    #
    # @return  [String]
    #
    def audit_id( injection_str = '', opts = {} )
        vars = auditable.keys.sort.to_s

        str = ''
        str << "#{@auditor.fancy_name}:" if !opts[:no_auditor] && !orphan?

        str << "#{@action}:#{type}:#{vars}"
        str << "=#{injection_str}" if !opts[:no_injection_str]
        str << ":timeout=#{opts[:timeout]}" if !opts[:no_timeout]

        str
    end

    # @note Mainly used by {Arachni::Module::Auditor#skip?} to prevent redundant
    #   audits for elements/issues which have already been logged as vulnerable.
    #
    # @return   [String]
    #   Predicts what the {Issue#unique_id} of an issue would look like,
    #   should `self` be vulnerable.
    def provisioned_issue_id( auditor_fanxy_name = @auditor.fancy_name )
        "#{auditor_fanxy_name}::#{type}::#{altered}::#{self.action.split( '?' ).first}"
    end

    # @return [Boolean]
    #   `true` if the element matches one or more {.skip_like_blocks},
    #   `false` otherwise.
    #
    # @see .skip_like_blocks
    def matches_skip_like_blocks?
        Arachni::Element::Capabilities::Auditable.matches_skip_like_blocks?( self )
    end

    #
    # Delegate output related methods to the auditor
    #

    def debug?
        @auditor.debug? rescue false
    end

    def print_error( str = '' )
        @auditor.print_error( str ) if !orphan?
    end

    def print_status( str = '' )
        @auditor.print_status( str ) if !orphan?
    end

    def print_info( str = '' )
        @auditor.print_info( str ) if !orphan?
    end

    def print_line( str = '' )
        @auditor.print_line( str ) if !orphan?
    end

    def print_ok( str = '' )
        @auditor.print_ok( str ) if !orphan?
    end

    def print_bad( str = '' )
        @auditor.print_bad( str ) if !orphan?
    end

    def print_debug( str = '' )
        @auditor.print_debug( str ) if !orphan?
    end

    def print_debug_backtrace( str = '' )
        @auditor.print_debug_backtrace( str ) if !orphan?
    end

    def print_error_backtrace( str = '' )
        @auditor.print_error_backtrace( str ) if !orphan?
    end

    private

    #
    # Submits mutations of self and calls the block to handle the responses.
    #
    # @note Requires an {#auditor}, if none has been provided it will fallback
    #   to an {#use_anonymous_auditor anonymous} one.
    #
    # @param  [String]  injection_str  The string to be injected.
    # @param  [Hash]    opts             Options as described in {OPTIONS}.
    # @param  [Block]   block
    #   Block to be used for analysis of responses; will be passed the following:
    #
    #     * HTTP response
    #     * options
    #     * element
    #
    #     The block will be called as soon as the HTTP response is received.
    #
    # @return   [Boolean]
    #   `true` if the audit was successful, `false` if:
    #
    #    * There are no {#auditable} inputs.
    #    * The {Element::Base#action} matches a {#skip_path? skip} rule.
    #    * The element has already been audited and the `:redundant` option
    #       is `false` -- the default.
    #    * The element matches a {.skip_like} block.
    #
    # @raise    ArgumentError   On missing `block`.
    #
    # @see #submit
    #
    def audit_single( injection_str, opts = { }, &block )
        fail ArgumentError, 'Missing block.' if !block_given?

        print_debug "About to audit: #{audit_id}"
        print_debug "Payload platform: #{opts[:platform]}" if opts.include?( :platform )

        # If we don't have any auditable elements just return.
        if auditable.empty?
            print_debug 'The element has no auditable inputs.'
            return false
        end

        if skip_path? self.action
            print_debug "Element's action matches skip rule, bailing out."
            return false
        end

        opts[:injected_orig] = injection_str

        @auditor ||= opts[:auditor]
        opts[:auditor] ||= @auditor
        use_anonymous_auditor if !@auditor

        audit_id = audit_id( injection_str, opts )
        return false if !opts[:redundant] && audited?( audit_id )

        if matches_skip_like_blocks?
            print_debug 'Element matches one or more skip_like blocks, skipping.'
            return false
        end

        # Iterate over all fuzz variations and audit each one.
        mutations( injection_str, opts ).each do |elem|

            if Options.exclude_vectors.include?( elem.altered )
                print_info "Skipping audit of '#{elem.altered}' #{type} vector."
                next
            end

            if !orphan? && @auditor.skip?( elem )
                mid = elem.audit_id( injection_str, opts )
                print_debug "Auditor's #skip? method returned true for mutation, skipping: #{mid}"
                next
            end

            if skip?( elem )
                mid = elem.audit_id( injection_str, opts )
                print_debug "Self's #skip? method returned true for mutation, skipping: #{mid}"
                next
            end

            opts[:altered] = elem.altered.dup
            opts[:element] = type

            # Inform the user about what we're auditing.
            print_status( elem.status_string ) if !opts[:silent]

            if opts[:each_mutation]
                if elements = opts[:each_mutation].call( elem )
                    [elements].flatten.compact.each do |e|
                        on_complete( e.submit( opts ), e, &block ) if e.is_a?( self.class )
                    end
                end
            end

            # Submit the element with the injection values.
            on_complete( elem.submit( opts ), elem, &block )
        end

        audited audit_id
        true
    end

    def skip_path?( url )
        super || redundant_path?( url )
    end

    # impersonate the auditor to the output methods
    def info
        !orphan? ? @auditor.class.info : { name: '' }
    end

    #
    # Registers a block to be executed as soon as the Typhoeus request (reg)
    # has been completed and a response has been received.
    #
    # If no &block has been provided {#get_matches} will be called instead.
    #
    # @param  [Typhoeus::Request]  req    request
    # @param  [Auditable]    elem    element
    # @param  [Block]   block
    #   Block to be used for analysis of responses; will be passed the following:
    #
    #     * HTTP response
    #     * options
    #     * element
    #
    #     The block will be called as soon as the HTTP response is received.
    #
    def on_complete( req, elem, &block )
        return if !req

        elem.opts[:injected] = elem.auditable[elem.altered].to_s
        elem.opts[:combo]    = elem.auditable
        elem.opts[:action]   = elem.action

        if !elem.opts[:async]
            after_complete( req.response, elem, &block ) if req && req.response
            return
        end

        req.on_complete { |res| after_complete( res, elem, &block ) }
    end

    def after_complete( response, element, &block )
        # make sure that we have a response before continuing
        if !response
            print_error 'Failed to get response, backing out...'
            return
        end

        if element.opts && !element.opts[:silent]
            print_status 'Analyzing response #' + response.request.id.to_s + '...'
        end

        exception_jail( false ){ block.call( response, element.opts, element ) }
    end

    def within_scope?
        auditor_override_instance_scope = false
        begin
            auditor_override_instance_scope = @auditor.override_instance_scope?
        rescue
        end

        override_instance_scope? || auditor_override_instance_scope ||
        @@restrict_to_elements.empty? || @@restrict_to_elements.include?( scope_audit_id )
    end

    #
    # Checks whether or not an audit has been already performed.
    #
    # @param  [String]  elem_audit_id  a string returned by {#audit_id}
    #
    # @see #audited
    #
    def audited?( elem_audit_id )
        if @@audited.include?( elem_audit_id )
            print_debug 'Skipping, already audited.'
            true
        elsif !within_scope?
            print_debug "Skipping, out of scope (#{scope_audit_id})."
            true
        else
            false
        end
    end

    #
    # Registers an audited element to avoid duplicate audits.
    #
    # @param  [String]  audit_id  {#audit_id Audit ID}.
    #
    # @see #audited?
    #
    def audited( audit_id )
        @@audited << audit_id
    end
    def self.audited
        @@audited
    end

    def self.skip_like_blocks
        @@skip_like_blocks
    end

    def self.matches_skip_like_blocks?( element )
        skip_like_blocks.each { |b| return true if b.call( element ) }
        false
    end

    def rehash
        @hash = (self.action.to_s + self.method.to_s + self.auditable.to_s).hash
    end

end

end
end
