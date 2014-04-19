=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

require 'nokogiri'
require Options.paths.lib + 'nokogiri/xml/node'

module Element

module Capabilities
end

# load and include all available capabilities
lib = File.dirname( __FILE__ ) + '/capabilities/*.rb'
Dir.glob( lib ).each { |f| require f }

# Base class for all element types.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Base
    include Utilities
    extend Utilities

    # @return   [Page]  Page this element belongs to.
    attr_accessor :page

    # @return   [Object]
    #   Options used to initialize an identical element.
    attr_reader   :initialization_options

    def initialize( options )
        options = options.symbolize_keys

        if !(options[:url] || options[:action])
            fail 'Needs :url or :action option.'
        end

        @initialization_options = options.dup
        self.url = options[:url] || options[:action]
    end

    # @return  [Element::Base] Reset the element to its original state.
    # @abstract
    def reset
        self
    end

    # @abstract
    def prepare_for_report
    end

    # @return  [String] String uniquely identifying self.
    def id
        "#{action}:#{method}:#{inputs.keys.sort}"
    end

    # @return   [Hash] Simple representation of self.
    def to_h
        {
            class: self.class.to_s,
            type:  type,
            url:   url
        }
    end
    def to_hash
        to_h
    end

    def hash
        to_h.hash
    end

    def ==( other )
        hash == other.hash
    end

    # @return  [String]
    #   URL of the page that owns the element.
    def url
        @url
    end

    def action
        url
    end

    # @see #url
    def url=( url )
        @url = normalize_url( url ).freeze
    end

    # @return [Symbol]  Element type.
    def type
        self.class.type
    end

    # @return [Symbol]  Element type.
    def self.type
        name.split( ':' ).last.downcase.to_sym
    end

    def dup
        self.class.new self.initialization_options
    end

    def marshal_dump
        instance_variables.inject({}) do |h, iv|
            next h if [:@page].include? iv
            h[iv] = instance_variable_get( iv )
            h
        end
    end

    def marshal_load( h )
        h.each { |k, v| instance_variable_set( k, v ) }
    end

    # @return   [Hash]
    #   Data representing this instance that are suitable the RPC transmission.
    def to_rpc_data
        data = marshal_dump.inject({}) { |h, (k, v)| h[k.to_s.gsub('@', '')] = v; h }
        data.delete 'audit_options'
        data['class'] = self.class
        data
    end

    # @param    [Hash]  data    {#to_rpc_data}
    # @return   [Base]
    def self.from_rpc_data( data )
        instance = allocate
        data.each do |name, value|
            value = case name
                        when 'dom'
                            self::DOM.from_rpc_data( value )

                        when 'initialization_options'
                            value.symbolize_keys

                        when 'method'
                            value.to_sym

                        else
                            value
                    end

            instance.instance_variable_set( "@#{name}", value )
        end

        instance.instance_variable_set( :@audit_options, {} )
        instance
    end

end
end
end
