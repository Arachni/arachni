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

lib = Arachni::Options.dir['lib']
require lib + 'bloom_filter'
require lib + 'module/utilities'
require lib + 'issue'
require lib + 'parser/element/mutable'

module Arachni
class Parser
module Element

#
# Namespace for all analysis techniques
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Analysis
end

#
# Provides audit functionality to {Arachni::Parser::Element::Mutable} elements.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Auditable
    include Arachni::Utilities
    include Arachni::Parser::Element::Mutable

    # load and include all available analysis/audit techniques
    lib = Options.instance.dir['lib'] + 'parser/element/analysis/*.rb'
    Dir.glob( lib ).each { |f| require f }
    Analysis.constants.each { |technique| include Analysis.const_get( technique ) }

    #
    # Empties the de-duplication/uniqueness look-up table.
    #
    # Unless you're sure you need this, set the :redundant flag to true
    # when calling audit methods to bypass it.
    #
    def self.reset
        @@audited = BloomFilter.new
    end
    reset

    #
    # Sets the auditor for this element.
    #
    # The auditor provides its output, HTTP and issue logging interfaces.
    #
    # @return   [Arachni::Module::Auditor]
    #
    attr_accessor :auditor

    #
    # Frozen version of {#auditable}, has all the original name/values
    #
    # @return   [Hash]
    #
    attr_reader   :orig

    #
    # @return [Hash]    audit and general options for convenience's sake
    #
    attr_reader   :opts

    #
    # Holds constants that describe the HTML elements to be audited.
    #
    module Element
        include Arachni::Issue::Element
    end

    #
    # Default audit options.
    #
    OPTIONS = {
        #
        # Enable skipping of already audited inputs
        #
        redundant: false,

        #
        # Make requests asynchronously
        #
        async:     true,

        #
        # Block to be passed each mutation right before being submitted.
        #
        # Allows for last minute changes.
        #
        each_mutation:  nil
    }

    #
    # Frozen Key=>value pairs of inputs.
    #
    # If you want to change it you'll either have to use {#update}
    # or the {#auditable=} attr_writer and pass a new hash -- the new hash will also be frozen.
    #
    # @return   [Hash]
    #
    def auditable
        @auditable.freeze
    end

    #
    # @param    [Hash]  hash    key=>value pair of inputs/params.
    #                               Will convert keys and values to string.
    #
    # @see auditable
    #
    def auditable=( hash )
        @auditable = (hash || {}).inject({}) { |h, (k, v)| h[k.to_s] = v.to_s.freeze; h}
        rehash
        self.auditable
    end

    #
    # @param    [Hash]  hash  key=>value pair of inputs/params with which to
    #                               update the #auditable inputs
    #
    # @see #auditable
    # @see #auditable=
    #
    def update( hash )
        self.auditable = self.auditable.merge( hash )
    end

    #
    # Shorthand {#auditable} reader
    #
    # @param    [#to_s] k   key
    #
    # @return   [String]
    #
    def []( k )
        self.auditable[k.to_s]
    end

    #
    # Shorthand {#auditable} writer
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
    # When called, the element will override the scope and be audited no-matter what.
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

    def self.reset_instance_scope
        @@restrict_to_elements = BloomFilter.new
    end

    #
    # Provides a more generalized audit ID which does not contain the
    # auditor's name, timeout value of injection string.
    #
    # Right now only used when in HPG mode to generate a white-list of
    # element IDs that are allowed to be audited.
    #
    # @param    [Hash]  opts    {#audit}    opts
    #
    def scope_audit_id( opts = {} )
        opts = {} if !opts
        audit_id( nil, opts.merge(
            no_auditor:       true,
            no_timeout:       true,
            no_injection_str: true
        ))
    end

    #
    # Restricts the audit to a specific set of elements.
    #
    # *Caution*: Each call overwrites the last.
    #
    # @param    [Array<String>]    elements     array of element/audit IDs by {#scope_audit_id}
    #
    # @see scope_audit_id
    #
    def self.restrict_to_elements( elements )
        self.reset_instance_scope
        elements.each { |elem| @@restrict_to_elements << elem }
    end

    #
    # Must be implemented by the including class and perform the appropriate
    # HTTP request (get/post/whatever) for the current element.
    #
    # Invoked by {#submit} to submit the object.
    #
    # @param    [Hash]      opts
    # @param    [Block]     block    callback to be passed the HTTP response
    #
    # @return   [Typhoeus::Request]
    #
    # @see #submit
    # @abstract
    #
    def http_request( opts, &block )
    end

    #
    # Returns the {#auditor}'s HTTP interface or reverts to Arachni::HTTP.instance
    #
    # @return   [Arachni::HTTP]
    #
    def http
        orphan? ? Arachni::HTTP : @auditor.http
    end

    #
    # @return   [Bool]  true if it has no auditor
    #
    def orphan?
        !@auditor
    end

    #
    # Resets the auditable inputs to their original format/values.
    #
    def reset
        self.auditable = @orig.dup
    end

    def remove_auditor
        @auditor = nil
    end

    #
    # Submits self using {#http_request}.
    #
    # @param  [Hash]  opts
    # @param  [Block]  block    callback to be passed the HTTP response
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

        opts.delete( :auditor )

        http_request( opts, &block )
    end

    def skip_path?( url )
        super || Options.redundant?( url )
    end

    #
    # Submits mutations of self and calls the block to handle the responses.
    #
    # Requires an {#auditor}.
    # Will remove the auditor after it's done unless {#keep_auditor} has been previously called.
    #
    # @param  [String]  injection_str  the string to be injected
    # @param  [Hash]    opts           options as described in {OPTIONS}
    # @param  [Block]   block         block to be used for analysis of responses; will be passed the following:
    #                                  * HTTP response
    #                                  * options
    #                                  * element
    #                                  The block will be called as soon as the
    #                                  HTTP response is received.
    #
    # @see #submit
    #
    def audit( injection_str, opts = { }, &block )
        raise 'Block required.' if !block_given?

        if skip_path?( self.action )
            print_debug "Element's action matches skip rule, bailing out (#{self.action})."
            return false
        end

        opts[:injected_orig] = injection_str

        # if we don't have any auditable elements just return
        if auditable.empty?
            print_debug "The element has no auditable inputs, returning."
            return false
        end

        @auditor ||= opts[:auditor]
        opts[:auditor] ||= @auditor

        audit_id = audit_id( injection_str, opts )
        return false if !opts[:redundant] && audited?( audit_id )

        # iterate through all variation and audit each one
        mutations( injection_str, opts ).each do |elem|

            if Arachni::Options.instance.exclude_vectors.include?( elem.altered )
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

            # inform the user about what we're auditing
            print_status( elem.status_string ) if !opts[:silent]

            if opts[:each_mutation]
                if elements = opts[:each_mutation].call( elem )
                    [elements].flatten.compact.each do |e|
                        on_complete( e.submit( opts ), e, &block ) if e.is_a?( self.class )
                    end
                end
            end

            # submit the element with the injection values
            on_complete( elem.submit( opts ), elem, &block )
        end

        audited( audit_id )
        true
    end

    def skip?( elem )
        false
    end

    #
    # Returns a status string explaining what's being audited.
    #
    # The string contains the name of the input that is being audited,
    # the url and the type of the input (form, link, cookie...).
    #
    # @return  [String]
    #
    def status_string
        "Auditing #{self.type} variable '#{self.altered}' with action '#{self.action}'."
    end

    #
    # Returns an audit ID string used to avoid redundant audits or identify the element.
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

        str << "#{@action}:" + "#{type}:#{vars}"
        str << "=#{injection_str.to_s}" if !opts[:no_injection_str]
        str << ":timeout=#{opts[:timeout]}" if !opts[:no_timeout]

        str
    end

    #
    # Predicts what the {Issue#unique_id} of an issue would look like,
    # should self be vulnerable.
    #
    # Mainly used by {Auditor#skip?} to prevent redundant audits for elements/issues
    # which have already been logged as vulnerable.
    #
    # @return   [String]
    #
    def provisioned_issue_id( auditor_fanxy_name = @auditor.fancy_name )
        "#{auditor_fanxy_name}::#{type}::#{altered}::#{self.action.split( '?' ).first}"
    end

    # impersonate the auditor to the output methods
    def info
        !orphan? ? @auditor.class.info : { name: '' }
    end

    # Do not remove the auditor after the audit
    def keep_auditor
        self.opts[:keep_auditor] = true
    end

    def keep_auditor?
        !!self.opts[:keep_auditor]
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
    # Registers a block to be executed as soon as the Typhoeus request (reg)
    # has been completed and a response has been received.
    #
    # If no &block has been provided {#get_matches} will be called instead.
    #
    # @param  [Typhoeus::Request]  req    request
    # @param  [Arachni::Parser::Element::Auditable]    elem    element
    # @param  [Block]   block         block to be passed the:
    #                                   * HTTP response
    #                                   * name of the input vector
    #                                   * updated opts
    #                                    The block will be called as soon as the
    #                                    HTTP response is received.
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

        #p = proc do |r, e|
        #    block.call( r, e.opts, e )
        #
        #    # nil-out the auditor to help out the GC
        #    remove_auditor if !keep_auditor?
        #end
        #exception_jail( false ){ p.call( response, element ) }
        exception_jail( false ){ block.call( response, element.opts, element ) }
    end

    def within_scope?
        @@restrict_to_elements ||= BloomFilter.new

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
    def audited?( elem_audit_id )
        ret = false
        if @@audited.include?( elem_audit_id )
            msg = "Skipping, already audited: #{elem_audit_id}"
            ret = true
        elsif !within_scope?
            msg = 'Skipping, out of instance scope.'
            ret = true
        else
            msg = 'Current audit ID: ' + elem_audit_id
            ret = false
        end

        print_debug( msg )

        ret
    end

    #
    # Registers an audit
    #
    # @param  [String]  audit_id  a string returned by {#audit_id}
    #
    def audited( audit_id )
        @@audited << audit_id
    end

    def self.audited
        @@audited
    end

    def rehash
        @hash = (self.action.to_s + self.method.to_s + self.auditable.to_s).hash
    end

end

end
end
end
