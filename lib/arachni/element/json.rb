=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'rack'
require 'rack/typhoeus/middleware/params_decoder'
require_relative 'base'

module Arachni::Element

# Represents an auditable JSON element
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class JSON < Base
    include Capabilities::Analyzable

    # @return   [String]
    #   Original JSON data.
    attr_accessor :json

    # @param    [Hash]    options
    # @option   options [String]    :url
    #   URL of the page which includes the link.
    # @option   options [String]    :action
    #   Link URL -- defaults to `:url`.
    # @option   options [Hash]    :inputs
    #   Query parameters as `name => value` pairs. If none have been provided
    #   they will automatically be extracted from {#action}.
    def initialize( options )
        self.http_method = options[:method] || :post

        super( options )

        @json = options[:json]

        self.inputs = (self.inputs || {}).merge( options[:inputs] || {} )

        if @json && self.inputs.empty?
            self.inputs = JSON.load( self.json )
        end

        @default_inputs = self.inputs.dup.freeze
    end

    # Overrides {Capabilities::Inputtable#inputs=} to allow for non-string data
    # of variable depth.
    #
    # @param    (see Capabilities::Inputtable#inputs=)
    # @return   (see Capabilities::Inputtable#inputs=)
    # @raise    (see Capabilities::Inputtable#inputs=)
    #
    # @see  Capabilities::Inputtable#inputs=
    def inputs=( h )
        h = h.my_stringify_keys

        @inputs = h
        update h
        @inputs.freeze
        self.inputs
    end

    # Overrides {Capabilities::Mutable#affected_input_name=} to allow for
    # non-string data of variable depth.
    #
    # @param    [Array<String>, String]    name
    #   Sets the name of the fuzzed input.
    #
    #   If the `name` is an `Array`, it will be treated as a path to the location
    #   of the input.
    #
    # @see  Capabilities::Mutable#affected_input_name=
    def affected_input_name=( name )
        if name.is_a?( Array ) && name.size == 1
            name = name.first
        end

        @affected_input_name = name
    end

    # Overrides {Capabilities::Inputtable#[]} to allow for non-string data
    # of variable depth.
    #
    # @param    [Array<String>, String]    name
    #   Name of the input whose value to retrieve.
    #
    #   If the `name` is an `Array`, it will be treated as a path to the location
    #   of the input.
    #
    # @return   [Object]
    #
    # @see  Capabilities::Inputtable#[]
    def []( name )
        key, data = find( name )
        data[key]
    end

    # Overrides {Capabilities::Inputtable#[]=} to allow for non-string data
    # of variable depth.
    #
    # @param    [Array<String>, String]    name
    #   Name of the input whose value to set.
    #
    #   If the `name` is an `Array`, it will be treated as a path to the location
    #   of the input.
    # @param    [Object]    value
    #   Value to set.
    #
    # @return   [Object]
    #   `value`
    #
    # @see  Capabilities::Inputtable#[]=
    def []=( name, value )
        @inputs = @inputs.dup
        key, data = find( name )

        fail_if_invalid( [key].flatten.last, value )

        data[key] = value
        @inputs.freeze
        value
    end

    # Overrides {Capabilities::Inputtable#update} to allow for non-string data
    # of variable depth.
    #
    # @param    (see Capabilities::Inputtable#update)
    # @return   (see Capabilities::Inputtable#update)
    # @raise    (see Capabilities::Inputtable#update)
    #
    # @see  Capabilities::Inputtable#update
    def update( hash )
        traverse_data hash do |path, value|
            self[path] = value
        end
        self
    end

    # @note (see Capabilities::Mutable#each_mutation)
    #
    # Overrides {Capabilities::Mutable#each_mutation} to allow for auditing of
    # non-string data of variable depth.
    #
    # @param    (see Capabilities::Mutable#each_mutation)
    # @yield    (see Capabilities::Mutable#each_mutation)
    #
    # @see  Capabilities::Mutable#each_mutation
    def each_mutation( payload, opts = {} )
        return if self.inputs.empty?

        if !valid_input_data?( payload )
            print_debug_level_2 "Payload not supported by #{self}: #{payload.inspect}"
            return
        end

        print_debug_trainer( opts )
        print_debug_formatting( opts )

        opts = MUTATION_OPTIONS.merge( opts )

        generated = Arachni::Support::LookUp::HashSet.new( hasher: :mutable_id )

        opts[:format].each do |format|
            traverse_inputs do |path, value|
                next if self[path] == seed || immutable_input?( path )

                str = format_str( payload, value.to_s, format )
                if !valid_input_value_data?( str )
                    print_debug_level_2 'Payload not supported as input value by' <<
                                            " #{audit_id}: #{str.inspect}"
                    next
                end

                elem                      = self.dup
                elem.seed                 = payload
                elem.affected_input_name  = path
                elem.affected_input_value = str
                elem.format               = format

                if !generated.include?( elem )
                    print_debug_mutation elem
                    yield elem
                end

                generated << elem
            end
        end

        if opts[:param_flip]
            if valid_input_name_data?( payload )
                elem                     = self.dup
                elem.affected_input_name = 'Parameter flip'
                elem.inputs              = elem.inputs.merge( payload => seed )
                elem.seed                = payload

                if !generated.include?( elem )
                    print_debug_mutation elem
                    yield elem
                end
                generated << elem
            else
                print_debug_level_2 'Payload not supported as input name by' <<
                                        " #{audit_id}: #{payload.inspect}"
                return
            end
        end

        nil
    end

    # @return   [String]
    #   JSON formatted {#inputs}.
    def to_json
        @inputs.to_json
    end

    def to_h
        super.merge( json: @json )
    end

    # @return   [Hash]
    #   Simple representation of self in the form of `{ {#action} => {#inputs} }`.
    def simple
        { self.action => self.inputs }
    end

    # @param   (see .encode)
    # @return  (see .encode)
    #
    # @see .encode
    def encode( *args )
        self.class.encode( *args )
    end

    # @param   (see .decode)
    # @return  (see .decode)
    #
    # @see .decode
    def decode( *args )
        self.class.decode( *args )
    end

    def dup
        d = super
        d.json   = @json
        d.inputs = @inputs.deep_clone
        d
    end

    class <<self

        # No-op
        def encode( v )
            v
        end

        # No-op
        def decode( v )
            v
        end

        # Extracts JSON elements from an HTTP request.
        #
        # @param   [Arachni::HTTP::Request]    request
        #
        # @return   [JSON, nil]
        def from_request( url, request )
            return if !request.body.is_a?( String ) || request.body.empty?

            data =  begin
                ::JSON.load( request.body )
            rescue ::JSON::ParserError
            end

            return if !data || data.empty?

            new(
                url:    url,
                action: request.url,
                method: request.method,
                inputs: data,
                json:   request.body
            )
        end

    end

    private

    def http_request( opts, &block )
        opts[:body]   = ::URI.encode_www_form_component( self.to_json )
        opts[:method] = self.http_method
        http.request( self.action, opts, &block )
    end

    def immutable_input?( path )
        [path].flatten.each do |name|
            return true if immutables.include?( name )
        end
        false
    end

    def find( path )
        data = @inputs
        path = [path].flatten

        while path.size > 1
            k = path.shift
            k = k.to_s if k.is_a? Symbol

            data = data[k]
        end

        k = path.shift
        k = k.to_s if k.is_a? Symbol

        [k, data]
    end

    def traverse_inputs( &block )
        traverse_data( @inputs, &block )
    end

    def traverse_data( data, path = [], &handler )
        case data
            when Hash
                data.each do |k, v|
                    traverse_data( v, path + [k], &handler )
                end

            when Array
                data.each.with_index do |v, i|
                    traverse_data( v, path + [i], &handler )
                end

            else
                handler.call path, data
        end
    end

end
end

Arachni::JSON = Arachni::Element::JSON
