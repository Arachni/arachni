=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'ox'

Ox.default_options = {
    indent:          4,
    mode:            :generic,
    effort:          :tolerant,
    smart:           true,
    invalid_replace: nil
}

module Arachni

lib = Options.paths.lib

# Load all available element types.
Dir.glob( lib + 'element/*.rb' ).each { |f| require f }
Dir.glob( lib + 'parser/**/*.rb' ).each { |f| require f }

require lib + 'page'
require lib + 'utilities'
require lib + 'component/manager'

# Analyzes HTML code extracting inputs vectors and supporting information.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Parser
    include UI::Output
    include Utilities


    CACHE_SIZES = {
        parse:          50,
        parse_xml:      50,
        parse_fragment: 100
    }

    CACHE = {}
    CACHE_SIZES.each do |name, size|
        CACHE[name] = Support::Cache::LeastRecentlyPushed.new( size )
    end

    WHITELIST = %w(
        title base a form frame iframe meta input select option script link area
        textarea input select button comment
    )

    class <<self

        def parse( html, options = {} )
            CACHE[__method__].fetch [html, options] do

                document = options[:handler] || SAX::Document.new( options )

                sax_options = {}
                if options[:whitelist] && options[:whitelist].any?
                    sax_options[:active] = options[:whitelist].to_a
                end

                begin
                    Ox.sax_html( document, StringIO.new( html ), sax_options )
                rescue SAX::Document::Stop
                end

                document

                # Document.new( Ox.parse( "<!DOCTYPE html>#{html}" ) )
            end
        end

        def parse_fragment( html )
            CACHE[__method__].fetch html do
                parse( html ).children.first
            end
        end

        def parse_xml( xml )
            CACHE[__method__].fetch xml do
                Ox.parse( xml )
            end
        end

        def markup?( string )
            begin
                parse_xml( string ).is_a?( Ox::Element )
            rescue => e
                false
            end
        end

    end

    alias :skip? :skip_path?

    # @return    [String]
    attr_reader :url

    # @return   [HTTP::Response]
    attr_reader :response

    # @param  [HTTP::Response, Array<HTTP::Response>] response
    #   Response(s) to analyze and parse. By providing multiple responses the
    #   parser will be able to perform some preliminary differential analysis
    #   and identify nonce tokens in inputs.
    #
    # @param  [Options] options
    def initialize( response, options = Options )
        @options = options

        if response.is_a? Array
            @secondary_responses = response[1..-1]
            @secondary_responses.compact! if @secondary_responses
            response = response.shift
        end

        @response = response
        self.url  = response.url
    end

    def url=( str )
        @url = normalize_url( uri_decode( str ) )
        @url = normalize_url( str ) if !@url
        @url.freeze
    end

    # Converts a relative URL to an absolute one.
    #
    # @param    [String]    relative_url
    #   URL to convert to absolute.
    #
    # @return   [String]
    #   Absolute URL.
    def to_absolute( relative_url )
        if (url = base)
            base_url = url
        else
            base_url = @url
        end

        super( relative_url, base_url )
    end

    # @return   [Page]
    def page
        @page ||= Page.new( parser: self )
    end

    # @return   [Boolean]
    #   `true` if the given HTTP response data are text based, `false` otherwise.
    def text?
        !@body.to_s.empty? || @response.text?
    end

    # @return    [String]
    #   Override the {#response} body for the parsing process.
    def body=( string )
        @links = @forms = @cookies = @document = nil
        @body = string
    end

    def body
        @body || @response.body
    end

    # @return   [Nokogiri::HTML, nil]
    #   Returns a parsed HTML document from the body of the HTTP response or
    #   `nil` if the response data wasn't {#text? text-based} or the response
    #   couldn't be parsed.
    def document
        return if !text?

        @document = self.class.parse( body, whitelist: WHITELIST )
    end

    # @note It will include common request headers as well headers from the HTTP
    #   request.
    #
    # @return    [Hash]
    #   List of valid auditable HTTP header fields.
    def headers
        @headers ||= {
            'Accept'          => 'text/html,application/xhtml+xml,application' +
                '/xml;q=0.9,*/*;q=0.8',
            'Accept-Charset'  => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'From'            => @options.authorized_by  || '',
            'User-Agent'      => @options.http.user_agent || '',
            'Referer'         => @url,
            'Pragma'          => 'no-cache'
        }.merge( response.request.headers ).
            map { |k, v| Header.new( url: @url, inputs: { k => v } ) }.freeze
    end

    # @return [Array<Element::Form>]
    #   Forms from {#document}.
    def forms
        return @forms.freeze if @forms
        return [] if !text? || !Form.in_html?( body )

        f = Form.from_parser( self )
        return f if !@secondary_responses

        @secondary_responses.each do |response|
            next if response.body.to_s.empty?

            Form.from_parser( Parser.new( response ) ).each do |form2|
                f.each do |form|
                    next if "#{form.coverage_id}:#{form.name_or_id}" !=
                        "#{form2.coverage_id}:#{form2.name_or_id}"

                    form.inputs.each do |k, v|
                        next if v == form2.inputs[k] ||
                            form.field_type_for( k ) != :hidden

                        form.nonce_name = k
                    end
                end
            end
        end

        @forms = f
    end

    # @return [Element::Link]
    #   Link to the page.
    def link
        return if link_vars.empty? && !@response.redirection?
        Link.new( url: @url, inputs: link_vars )
    end

    # @return [Element::LinkTemplate]
    #   LinkTemplate for the current page.
    def link_template
        template, inputs = LinkTemplate.extract_inputs( @url )
        return if !template

        LinkTemplate.new(
            url:      @url.freeze,
            action:   @url.freeze,
            inputs:   inputs,
            template: template
        )
    end

    # @return [Array<Element::Link>]
    #   Links in {#document}.
    def links
        return @links.freeze if @links
        return @links = [link].compact if !text? || !Link.in_html?( body )

        @links = [link].compact | Link.from_parser( self )
    end

    # @return [Array<Element::LinkTemplate>]
    #   Links matching {Arachni::OptionsGroups::Audit#link_templates} in {#document}.
    def link_templates
        return @link_templates.freeze if @link_templates
        return @link_templates = [link_template].compact if !text?

        @link_templates =
            [link_template].compact | LinkTemplate.from_parser( self )
    end

    # @return [Array<Element::JSON>]
    def jsons
        @jsons ||= [JSON.from_request( @url, response.request )].compact
    end

    # @return [Array<Element::XML>]
    def xmls
        @xmls ||= [XML.from_request( @url, response.request )].compact
    end

    # @return   [Hash]
    #   Parameters found in {#url}.
    def link_vars
        return {} if !(parsed = uri_parse( @url ))

        @link_vars ||= parsed.rewrite.query_parameters.freeze
    end

    # Dummy method, only the {Browser#to_page browser} can fill this in.
    def ui_inputs
        []
    end

    # Dummy method, only the {Browser#to_page browser} can fill this in.
    def ui_forms
        []
    end

    # @return   [Array<Element::Cookie>]
    #   Cookies from HTTP headers and response body.
    def cookies
        return @cookies.freeze if @cookies

        @cookies = Cookie.from_headers( @url, @response.headers )
        return @cookies if !text? || !Cookie.in_html?( body )

        @cookies |= Cookie.from_parser( self )
    end

    # @return   [Array<Element::Cookie>]
    #   Cookies to be audited.
    def cookies_to_be_audited
        return @cookies_to_be_audited.freeze if @cookies_to_be_audited
        return [] if !text?

        # Make a list of the response cookie names.
        cookie_names = Set.new( cookies.map(&:name) )

        # Grab all cookies from the cookiejar giving preferrence to the ones
        # specified by the current page, if there are any.
        from_http_jar = HTTP::Client.cookie_jar.cookies.reject do |c|
            cookie_names.include?( c.name )
        end

        # These cookies are to be audited and thus are dirty and anarchistic,
        # so they have to contain even cookies completely irrelevant to the
        # current page. I.e. it contains all cookies that have been observed
        # since the beginning of the scan
        @cookies_to_be_audited = (cookies | from_http_jar).map do |c|
            dc = c.dup
            dc.action = @url
            dc
        end
    end

    # @return   [Array<Element::Cookie>]
    #   Cookies with which to update the HTTP cookie-jar.
    def cookie_jar
        return @cookie_jar.freeze if @cookie_jar
        from_jar = []

        # Make a list of the response cookie names.
        cookie_names = Set.new( cookies.map( &:name ) )

        from_jar |= HTTP::Client.cookie_jar.for_url( @url ).
            reject { |cookie| cookie_names.include?( cookie.name ) }

        @cookie_jar = (cookies | from_jar)
    end

    # @return   [Array<String>]
    #   Distinct links to follow.
    def paths
      return @paths if @paths
      @paths = []
      return @paths.freeze if !document

      @paths = run_extractors.freeze
    end

    # @return   [String]
    #   Base `href`, if there is one.
    def base
        @base ||= document.nodes_by_name( :base ).map { |b| b['href'] }.first || @url
    end

    private

    # Runs all path extraction components and returns an array of paths.
    #
    # @return   [Array<String>]
    #   Paths.
    def run_extractors
        begin
            unsanitized_paths = Set.new
            self.class.extractors.available.each do |name|
                exception_jail false do
                    unsanitized_paths.merge self.class.extractors[name].new(
                        parser: self,
                        html:   body
                    ).run
                end
            end

            sanitized_paths = Set.new
            unsanitized_paths.map do |path|
                abs = to_absolute( path )
                next if !abs || skip?( abs )

                sanitized_paths << abs
            end

            sanitized_paths.to_a
        rescue => e
            print_exception e
            []
        end
    end

    def self.extractors
        @manager ||= Component::Manager.new( Options.paths.path_extractors, Extractors )
    end

end
end
