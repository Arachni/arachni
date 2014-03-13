=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'output'

module Arachni
module Element::Capabilities
module Auditable

# Provides access to DOM operations for {Element elements}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class DOM
    include Auditable::Output
    include Auditable

    extend Forwardable

    # @return   [Element::Base]
    attr_accessor :parent

    # @return   [Browser]
    attr_accessor :browser

    attr_reader   :url

    attr_reader   :action

    attr_accessor :page

    attr_accessor :html

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
            @html   = parent.html.dup.freeze   if parent.html
        else
            @url    = options[:url].freeze
            @action = options[:action].freeze
            @page   = options[:page]
            @html   = options[:html].freeze
        end

        @audit_options = {}
    end

    def node
        return if !@html
        Nokogiri::HTML.fragment( @html ).children.first
    end

    def url=(*)
        fail NotImplementedError
    end

    def action=(*)
        fail NotImplementedError
    end

    def page
        return @page if @page
        @page = parent.page if parent
    end

    # @return   [Watir::HTMLElement]
    def element
        @element ||= locate
    end

    # Overrides {Capabilities::Mutable#each_mutation} to handle DOM limitations.
    #
    # @param (see Capabilities::Mutable#each_mutation)
    # @return (see Capabilities::Mutable#each_mutation)
    # @yield (see Capabilities::Mutable#each_mutation)
    # @yieldparam (see Capabilities::Mutable#each_mutation)
    #
    # @see Capabilities::Mutable#each_mutation
    def each_mutation( injection_str, opts = {} )
        super( injection_str, opts ) do |mutation|
            # DOM operations don't support nulls.
            next if (mutation.format & Format::NULL) != 0
            yield mutation
        end
    end

    # @param  [Hash]  options
    # @param  [Block]  block    Callback to be passed the evaluated {Page}.
    def submit( options = {}, &block )
        with_browser do |browser|
            prepare_browser( browser, options )
            trigger

            # If we've wondered to an out-of-scope resource don't bother calling.
            # Can be caused by a JS redirect or something akin to that.
            if (page = browser.to_page)
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

    def dup
        new = self.class.new( dup_options )
        new.parent = parent
        copy_auditable( copy_mutable( copy_inputable( new ) ) )
    end

    def hash
        inputs.hash
    end

    def ==( other )
        hash == other.hash
    end

    def marshal_dump
        instance_variables.inject( {} ) do |h, iv|
            next h if [:@parent, :@page].include? iv
            h[iv] = instance_variable_get( iv )
            h
        end
    end

    def marshal_load( h )
        h.each { |k, v| instance_variable_set( k, v ) }
    end

    private

    def dup_options
        options = {}
        options[:url]    = url.dup     if @url
        options[:action] = @action.dup if @action
        options[:page]   = page        if page
        options[:html]   = @html.dup   if @html
        options
    end

    def prepare_browser( browser, options )
        @browser = browser
        browser.javascript.custom_code = options[:custom_code]

        browser.load page
    end

    def on_complete( page, &block )
        block.call page, page.request.performer
    end

end

end
end
end
