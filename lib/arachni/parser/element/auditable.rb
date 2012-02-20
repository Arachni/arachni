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

# namespace for all analysis techniques
module Analysis
end

module Auditable

    include Arachni::Module::Utilities
    include Arachni::Parser::Element::Mutable

    lib = Options.instance.dir['lib'] + 'parser/element/analysis/*.rb'
    Dir.glob( lib ).each { |f| require f }
    Analysis.constants.each {
        |technique|
        include( Analysis.const_get( technique ) )
    }

    def self.reset!
        @@audited = Set.new
    end

    attr_accessor :auditor
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

    def override_instance_scope!
        @override_instance_scope = true
    end

    def override_instance_scope?
        @override_instance_scope ||= false
    end

    #
    # Delegate output related methods to the auditor
    #

    def debug?
        @auditor.debug? rescue false
    end

    def print_error( str = '' )
        @auditor.print_error( str )
    end

    def print_status( str = '' )
        @auditor.print_status( str )
    end

    def print_debug( str = '' )
        @auditor.print_debug( str )
    end

    def print_debug_backtrace( str = '' )
        @auditor.print_debug_backtrace( str )
    end

    def print_error_backtrace( str = '' )
        @auditor.print_error_backtrace( str )
    end

    def type
        self.class.name.split( ':' ).last.downcase
    end

    #
    # ABSTRACT
    #
    # Callback invoked by {Arachni::Element::Auditable#audit} to submit
    # the object via {Arachni::Module::HTTP}.
    #
    # Must be implemented by the extending class.
    #
    # @param    [String]    url
    # @param    [Hash]      opts
    #
    # @return   [Typhoeus::Request]
    #
    # @see #submit
    #
    def http_request( opts )
    end

    def http
        @auditor.http
    end

    #
    # Submits self using {#http_request}.
    #
    # @param  [Hash]  opts
    #
    # @see #http_request
    # @see OPTIONS
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
    # @param  [Block]   &block         block to be used for custom analysis of responses; will be passed the following:
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

        results = []
        # iterate through all variation and audit each one
        mutations( injection_str, opts ).each {
            |elem|

            return if @auditor.skip?( elem )

            opts[:altered] = elem.altered.dup
            opts[:element] = type

            # inform the user about what we're auditing
            print_status( elem.status_string ) if !opts[:silent]

            # submit the element with the injection values
            req = elem.submit( opts )
            return if !req

            on_complete( req, elem, &block )
            req.after_complete {
                |result|
                results << result.flatten[1] if result.flatten[1]
            }
        }

        audited( audit_id )
    end

    # impersonate the auditor to the output methods
    def info
        @auditor ? @auditor.class.info : { :name => '' }
    end

    #
    # Returns a status string that explaining what's happening.
    #
    # The string contains the name of the input that is being audited
    # the url and the type of the input (form, link, cookie...)
    #
    # @param  [String]  url  the url under audit
    # @param  [Hash]  input
    # @param  [Hash]  opts
    #
    # @return  [String]
    #
    def status_string
        return "Auditing #{self.type} variable '" + self.altered + "' of " + @action
    end

    #
    # Returns am audit identifier string to be registered using {#audited}.
    #
    # @param  [Hash]  input
    # @param  [Hash]  opts
    #
    # @return  [String]
    #
    def audit_id( injection_str = '', opts = {} )
        vars = auditable.keys.sort.to_s

        str = ''
        str += !opts[:no_auditor] ? "#{@auditor.class.info[:name]}:" : ''

        str += "#{@action}:" + "#{self.type}:#{vars}"
        str += "=#{injection_str.to_s}" if !opts[:no_injection_str]
        str += ":timeout=#{opts[:timeout]}" if !opts[:no_timeout]

        return str
    end

    def self.restrict_to_elements!( elements )
        @@restrict_to_elements = Set.new
        elements.each {
            |elem|
            @@restrict_to_elements << elem
        }
    end

    private

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

        opts = {
            :no_auditor => true,
            :no_timeout => true,
            :no_injection_str => true
        }

        @@restrict_to_elements ||= Set.new

        if @@audited.include?( elem_audit_id )
            msg = 'Skipping, already audited: ' + elem_audit_id
            ret = true
        elsif !@auditor.override_instance_scope? && !override_instance_scope? &&
            !@@restrict_to_elements.empty? &&
            !@@restrict_to_elements.include?( audit_id( nil, opts ) )
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
    def audited( audit_id )
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
