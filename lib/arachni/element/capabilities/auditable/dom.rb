=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'forwardable'
require_relative '../with_node'

module Arachni
module Element::Capabilities
module Auditable

# Provides access to DOM operations for {Element elements}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module DOM
    include WithNode
    include Auditable
    extend ::Forwardable

    INVALID_INPUT_DATA = [ "\0" ]

    # @return   [Element::Base]
    attr_accessor :parent

    # @return   [Browser]
    attr_accessor :browser

    attr_reader   :action

    # @!method with_browser_cluster( &block )
    def_delegator :auditor, :with_browser_cluster

    # @!method with_browser( &block )
    def_delegator :auditor, :with_browser

    def initialize( options )
        options = options.dup
        @parent = options.delete(:parent)

        if parent
            @url    = parent.url.dup.freeze    if parent.url
            @action = parent.action.dup.freeze if parent.action
            @page   = parent.page              if parent.page
            @source = parent.source.dup.freeze   if parent.respond_to?(:source) && parent.source
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

    def valid_input_data?( data )
        !INVALID_INPUT_DATA.find { |c| data.include? c }
    end

    def page
        return @page if @page
        @page = parent.page if parent
    end

    # @return   [Watir::HTMLElement]
    def element
        @element ||= locate
    end

    # @param  [Hash]  options
    # @param  [Block]  block
    #   Callback to be passed the evaluated {Page}.
    def submit( options = {}, &block )
        with_browser do |browser|
            prepare_browser( browser, options )

            # If we've wondered to an out-of-scope resource don't bother calling.
            # Can be caused by a JS redirect or something akin to that.
            if (transition = trigger) && (page = browser.to_page)
                page.dom.transitions << transition
                block.call page.tap { |p| p.request.performer = self }
            end

            @element = nil
            @browser = nil
        end
        nil
    end

    def locator
        @locator ||= Browser::ElementLocator.from_node( node )
    end

    # Locates the element in the page.
    def locate
        locator.locate( browser )
    end

    # Triggers the event on the subject {#element}.
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
        options[:url]    = url.dup     if @url
        options[:action] = @action.dup if @action
        options[:page]   = page        if page
        options[:source] = @source.dup if @source
        options
    end

    private

    def prepare_browser( browser, options )
        @browser = browser
        browser.javascript.custom_code = options[:custom_code]
        browser.javascript.taint       = options[:taint]

        browser.load page
    end

end

end
end
end
