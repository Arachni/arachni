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


require Arachni::Options.instance.dir['lib'] + 'module/utilities'
require Arachni::Options.instance.dir['lib'] + 'issue'
require Arachni::Options.instance.dir['lib'] + 'parser/element/mutable'

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

    include Arachni::Module::Utilities
    include Arachni::Parser::Element::Mutable

    # load and include all available analysis/audit techniques
    lib = Options.instance.dir['lib'] + 'parser/element/analysis/*.rb'
    Dir.glob( lib ).each { |f| require f }
    Analysis.constants.each {
        |technique|
        include( Analysis.const_get( technique ) )
    }

    #
    # Empties the de-duplication/uniqueness look-up table.
    #
    # Unless you're sure you need this, set the :redundant flag to true
    # when calling audit methods to bypass it.
    #
    def self.reset!
        @@audited = Set.new
    end

    #
    # Sets the auditor for this element.
    #
    # The auditor provides its output and issue logging interfaces to the
    # auditable element.
    #
    # @param    [Arachni::Module::Auditor]
    # @return   [Arachni::Module::Auditor]
    #
    attr_accessor :auditor

    #
    # @return [Hash]    audit and general options for convinience's sake
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
        :redundant => false,

        #
        # Make requests asynchronously
        #
        :async     => true
    }

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
    def override_instance_scope!
        @override_instance_scope = true
    end

    def reset_scope_override!
        @override_instance_scope = false
    end

    #
    # Does this element override the instance scope?
    #
    # @see override_instance_scope!
    #
    def override_instance_scope?
        @override_instance_scope ||= false
    end

    def self.reset_instance_scope!
        @@restrict_to_elements = Set.new
    end

    #
    # Provides a more generalized audit ID which does not contain the
    # auditor's name, timeout value of injection string.
    #
    # Right now only used when in HPG mode to generate a whitelist of
    # element IDs that are allowed to be audited.
    #
    # @param    [Hash]  opts    {#audit}    opts
    #
    def scope_audit_id( opts = {} )
        opts = {} if !opts
        audit_id( nil, opts.merge(
            :no_auditor => true,
            :no_timeout => true,
            :no_injection_str => true
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
    def self.restrict_to_elements!( elements )
        self.reset_instance_scope!
        elements.each { |elem| @@restrict_to_elements << elem }
    end

    #
    # Must be implemented by the including class and perform the appropriate
    # HTTP request (get/post/whatever) for the current element.
    #
    # Invoked by {#submit} to submit the object.
    #
    # @param    [Hash]      opts
    #
    # @return   [Typhoeus::Request]
    #
    # @see #submit
    # @abstract
    #
    def http_request( opts )
    end

    #
    # Returns the {#auditor}'s HTTP interface or reverts to Arachni::HTTP.instance
    #
    # @return   [Arachni::HTTP]
    #
    def http
        orphan? ? Arachni::HTTP.instance : @auditor.http
    end

    #
    # @return   [Bool]  true if it has no auditor
    #
    def orphan?
        !@auditor
    end

    #
    # Submits self using {#http_request}.
    #
    # @param  [Hash]  opts
    #
    # @see #http_request
    #
    def submit( opts = {} )
        opts = OPTIONS.merge( opts )
        opts[:params]  = @auditable.dup
        @opts = opts

        @auditor ||= opts[:auditor] if opts[:auditor]

        opts.delete( :auditor )

        return http_request( opts )
    end

    #
    # Submits mutations of self and calls the block to handle the responses.
    #
    # @param  [String]  injection_str  the string to be injected
    # @param  [Hash]    opts           options as described in {OPTIONS}
    # @param  [Block]   &block         block to be used for analysis of responses; will be passed the following:
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

        @@audited ||= Set.new

        opts[:injected_orig] = injection_str

        # if we don't have any auditable elements just return
        return if auditable.empty?

        @auditor ||= opts[:auditor]
        opts[:auditor] ||= @auditor

        audit_id = audit_id( injection_str, opts )
        return if !opts[:redundant] && audited?( audit_id )

        # iterate through all variation and audit each one
        mutations( injection_str, opts ).each {
            |elem|
            return if !orphan? && @auditor.skip?( elem )

            opts[:altered] = elem.altered.dup
            opts[:element] = type

            # inform the user about what we're auditing
            print_status( elem.status_string ) if !opts[:silent]

            # submit the element with the injection values
            req = elem.submit( opts )
            return if !req
            on_complete( req, elem, &block )
        }

        audited!( audit_id )
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
        return "Auditing #{self.type} variable '" + self.altered + "' of " + @action
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
        str += !opts[:no_auditor] && !orphan? ? "#{@auditor.class.info[:name]}:" : ''

        str += "#{@action}:" + "#{type}:#{vars}"
        str += "=#{injection_str.to_s}" if !opts[:no_injection_str]
        str += ":timeout=#{opts[:timeout]}" if !opts[:no_timeout]

        return str
    end

    private

    # impersonate the auditor to the output methods
    def info
        !orphan? ? @auditor.class.info : { :name => '' }
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

    def print_debug( str = '' )
        @auditor.print_debug( str ) if !orphan?
    end

    def print_debug_backtrace( str = '' )
        @auditor.print_debug_backtrace( str ) if !orphan?
    end

    def print_error_backtrace( str = '' )
        @auditor.print_error_backtrace( str ) if !orphan?
    end

    #
    # Registers a block to be executed as soon as the Typhoeus request (reg)
    # has been completed and a response has been received.
    #
    # If no &block has been provided {#get_matches} will be called instead.
    #
    # @param  [Typhoeus::Request]  req
    # @param  [Arachni::Element::Auditable]    auditable element
    # @param  [Hash]    opts           an updated hash of options
    # @param  [Block]   &block         block to be passed the:
    #                                   * HTTP response
    #                                   * name of the input vector
    #                                   * updated opts
    #                                    The block will be called as soon as the
    #                                    HTTP response is received.
    #
    def on_complete( req, elem, &block )
        elem.opts[:injected] = elem.auditable[elem.altered].to_s
        elem.opts[:combo]    = elem.auditable
        elem.opts[:action]   = elem.action

        if( !elem.opts[:async] )
            if( req && req.response )
                after_complete( req.response, elem, &block )
            end
            return
        end

        req.on_complete { |res| after_complete( res, elem, &block ) }
    end

    def after_complete( response, element, &block )
        # make sure that we have a response before continuing
        if !response
            print_error( 'Failed to get response, backing out...' )
            return
        else
            if element.opts && !element.opts[:silent]
                print_status( 'Analyzing response #' + response.request.id.to_s + '...' )
            end
        end

        exception_jail( false ){
            block.call( response, element.opts, element )
        }
    end

    #
    # Checks whether or not an audit has been already performed.
    #
    # @param  [String]  elem_audit_id  a string returned by {#audit_id}
    #
    def audited?( elem_audit_id )
        @@restrict_to_elements ||= Set.new

        auditor_override_instance_scope = false
        begin
            auditor_override_instance_scope = @auditor.override_instance_scope?
        rescue
        end

        if @@audited.include?( elem_audit_id )
            msg = 'Skipping, already audited: ' + elem_audit_id
            ret = true
        elsif !auditor_override_instance_scope && !override_instance_scope? &&
            !@@restrict_to_elements.empty? &&
            !@@restrict_to_elements.include?( scope_audit_id( opts ) )
            msg = 'Skipping, out of instance scope.'
            ret = true
        else
            msg = 'Current audit ID: ' + elem_audit_id
            ret = false
        end

        print_debug( msg )

        return ret
    end

    #
    # Registers an audit
    #
    # @param  [String]  audit_id  a string returned by {#audit_id}
    #
    def audited!( audit_id )
        @@audited << audit_id
    end

    def print_debug_injection_set( var_combo, opts )
        return if !debug?

        print_debug( )
        print_debug_trainer( opts )
        print_debug_formatting( opts )
        print_debug_combos( var_combo )
    end

    def print_debug_formatting( opts )
        print_debug( '------------' )

        print_debug( 'Injection string format combinations set to:' )
        print_debug( '|')
        msg = []
        opts[:format].each {
            |format|

            if( format & Format::NULL ) != 0
                msg << 'null character termination (Format::NULL)'
            end

            if( format & Format::APPEND ) != 0
                msg << 'append to default value (Format::APPEND)'
            end

            if( format & Format::STRAIGHT ) != 0
                msg << 'straight, leave as is (Format::STRAIGHT)'
            end

            prep = msg.join( ' and ' ).capitalize + ". [Combo mask: #{format}]"
            prep.gsub!( 'format::null', "Format::NULL [#{Format::NULL}]" )
            prep.gsub!( 'format::append', "Format::APPEND [#{Format::APPEND}]" )
            prep.gsub!( 'format::straight', "Format::STRAIGHT [#{Format::STRAIGHT}]" )
            print_debug( "|----> " + prep )

            msg.clear
        }

    end

    def print_debug_combos( combos )

        print_debug( )
        print_debug( 'Prepared combinations:' )
        print_debug('|' )

        combos.each{
          |elem|

          altered = elem.altered
          combo   = elem.auditable


          print_debug( '|' )
          print_debug( "|--> Auditing: " + altered )
          print_debug( "|--> Combo: " )

          combo.each {
              |c_combo|
              print_debug( "|------> " + c_combo.to_s )
          }

        }

        print_debug( )
        print_debug( '------------' )
        print_debug( )

    end

    def print_debug_trainer( opts )
        print_debug( 'Trainer set to: ' + ( opts[:train] ? 'ON' : 'OFF' ) )
    end


end

end
end
end
