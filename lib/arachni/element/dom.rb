=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'base'

module Arachni::Element

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class DOM < Base

    # load and include all available capabilities
    lib = File.dirname( __FILE__ ) + '/dom/capabilities/*.rb'
    Dir.glob( lib ).each { |f| require f }

    include Arachni::Element::Capabilities::WithSource

    # @return   [Element::Base]
    attr_accessor :parent

    # @return   [Browser]
    attr_accessor :browser

    attr_reader   :action

    def initialize( options )
        options = options.dup
        @parent = options.delete(:parent)

        if parent
            @url    = parent.url.dup.freeze    if parent.url
            @action = parent.action.dup.freeze if parent.action
            @page   = parent.page              if parent.page
            @source = parent.source.dup.freeze if parent.respond_to?(:source) && parent.source
        else
            @url    = options[:url].freeze
            @action = options[:action].freeze
            @page   = options[:page]
            @source = options[:source].freeze
        end

        @audit_options = {}
    end

    def url=(*)
        # NOP
    end

    def action=(*)
        # NOP
    end

    def page
        return @page if @page
        @page = parent.page if parent
    end

    # Triggers the event on the subject {#element}.
    #
    # @return   [Array<Page::DOM::Transition>]
    #
    # @abstract
    def trigger
        fail NotImplementedError
    end

    # Removes the associated {#page}, {#parent} and {#browser}
    def prepare_for_report
        super

        @page    = nil
        @parent  = nil
        @element = nil
        @browser = nil
    end

    def dup
        super.tap { |new| new.parent = parent }
    end

    def marshal_dump
        super.reject{ |k, _| [:@parent, :@page, :@browser, :@element].include? k }
    end

    def initialization_options
        options = {}
        options[:url]    = @url.dup    if @url
        options[:action] = @action.dup if @action
        # options[:page]   = @page       if @page
        options[:source] = @source.dup if @source
        options
    end

    def encode( string )
        self.class.encode( string )
    end

    def decode( string )
        self.class.decode( string )
    end

    def self.encode( string )
        string
    end

    def self.decode( string )
        string
    end

end

end
