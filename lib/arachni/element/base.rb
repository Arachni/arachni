=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'nokogiri'

module Arachni

module Element

def self.type_to_class( type )
    Element.constants.each do |c|
        klass = Element.const_get( c )
        return klass if klass.respond_to?(:type) && klass.type == type
    end
    nil
end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Error < Arachni::Error
end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Capabilities

    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Element::Error
    end
end

file = File.dirname( __FILE__ )
# Need to be loaded in order.
%w(inputtable submittable mutable auditable analyzable).each do |name|
    require_relative "#{file}/capabilities/#{name}.rb"
end
# Load the rest automatically.
Dir.glob( "#{file}/capabilities/*.rb" ).each { |f| require f }

# Base class for all element types.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @abstract
class Base
    include Utilities
    extend Utilities

    include Capabilities::WithScope

    # Maximum element size in bytes.
    # Anything larger than this should be exempt from parse and storage or have
    # its value ignored.
    #
    # During the audit, thousands of copies will be generated and the same
    # amount of HTP requests will be stored in the HTTP::Client queue.
    # Thus, elements with inputs of excessive size will lead to excessive RAM
    # consumption.
    #
    # This will almost never be necessary, but there have been cases of
    # buggy `_VIEWSTATE` inputs that grow infinitely.
    MAX_SIZE = 10_000

    # @return     [Page]
    #   Page this element belongs to.
    attr_accessor :page

    # @return     [Object]
    #   Options used to initialize an identical element.
    attr_reader   :initialization_options

    def initialize( options )
        if !(options[:url] || options[:action])
            fail 'Needs :url or :action option.'
        end

        @initialization_options = options.dup
        self.url = options[:url] || options[:action]
    end

    # @return  [Element::Base]
    #   Reset the element to its original state.
    # @abstract
    def reset
        self
    end

    # @abstract
    def prepare_for_report
    end

    # @return  [String]
    #   String uniquely identifying self.
    def id
        defined? super ? super : "#{action}:#{type}"
    end

    # @return   [Hash]
    #   Simple representation of self.
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
        id.hash
    end

    def persistent_hash
        id.persistent_hash
    end

    def ==( other )
        hash == other.hash
    end
    alias :eql? :==

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

    # @return   [Symbol]
    #   Element type.
    def type
        self.class.type
    end

    # @return   [Symbol]
    #   Element type.
    def self.type
        @type ||= name.split( ':' ).last.downcase.to_sym
    end

    def dup
        dupped = self.class.new( self.initialization_options )
        dupped.page = page
        dupped
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
        data = marshal_dump.inject({}) do |h, (k, v)|
            h[k.to_s.gsub('@', '')] = v.to_rpc_data_or_self
            h
        end

        data.delete 'audit_options'
        data.delete 'scope'

        data['class']                  = self.class.to_s
        data['initialization_options'] = initialization_options

        if data['initialization_options'].is_a? Hash
            data['initialization_options'] =
                data['initialization_options'].my_stringify_keys(false)
        end

        data
    end

    # @param    [Hash]  data    {#to_rpc_data}
    # @return   [Base]
    def self.from_rpc_data( data )
        instance = allocate
        data.each do |name, value|
            value = case name
                        when 'dom'
                            next if !value
                            self::DOM.from_rpc_data( value )

                        when 'locator'
                            next if !value
                            Browser::ElementLocator.from_rpc_data( value )

                        when 'initialization_options'
                            value.is_a?( Hash ) ?
                                value.my_symbolize_keys( false ) : value

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

    def self.too_big?( element )
        (element.is_a?( Numeric ) ? element : element.to_s.size) >= MAX_SIZE
    end

end
end
end
