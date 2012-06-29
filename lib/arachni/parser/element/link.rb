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

require Arachni::Options.instance.dir['lib'] + 'parser/element/base'
class Arachni::Parser::Element::Link < Arachni::Parser::Element::Base

    #
    # Creates a new Link element from a URL or more complex data.
    #
    # @param    [String]    url     owner URL -- URL of the page which contained the
    # @param    [String, Hash]    raw
    #   If empty, the owner URL will be treated as the actionable URL and
    #   auditable inputs will be extracted from its query component.
    #
    #   If a +String+ is passed, it will be treated as the actionable
    #   URL and auditable inputs will be extracted from its query component.
    #
    #   If a +Hash+ is passed, it will look for an actionable URL
    #   +String+ in the following keys:
    #   * 'href'
    #   * :href
    #   * 'action'
    #   * :action
    #
    #   and for an auditable inputs +Hash+ in:
    #   * 'vars'
    #   * :vars
    #   * 'inputs'
    #   * :inputs
    #
    #   these should contain inputs in name=>value pairs.
    #
    #   If the +Hash+ doesn't contain any of the following keys,
    #   its contents will be used as auditable inputs instead and +url+ will be
    #   used as the actionable URL.
    #
    #   If no inputs have been provided it will try to extract some from the
    #   actionable URL, if empty inputs (empty +Hash+) )have been provided the URL will not be
    #   parsed and the Link will instead be configured without any auditable inputs/vectors.
    #
    #
    def initialize( url, raw = {} )
        super( url, raw )

        if !@raw || @raw.empty?
            self.action = self.url
        elsif raw.is_a?( String )
            self.action = @raw
        elsif raw.is_a?( Hash )
            keys = raw.keys
            has_input_hash  = (keys & ['vars', :vars, 'inputs', :inputs]).any?
            has_action_hash = (keys & ['href', :href, 'action', :action]).any?

            if !has_input_hash && !has_action_hash
                self.auditable = @raw
            else
                self.auditable = @raw['vars'] || @raw[:vars] || @raw['inputs'] || @raw[:inputs]
            end
            self.action = @raw['href'] || @raw[:href] || @raw['action'] || @raw[:action]
        end

        self.auditable ||= self.class.parse_query_vars( self.action )

        if @raw.is_a?( String )
            @raw = {
                action: self.action,
                inputs: self.auditable
            }
        end

        self.method = 'get'

        @orig = self.auditable.dup
        @orig.freeze
    end

    # @return   [Hash]  Simple representation of self in the form of { {#action} => {#auditable} }
    def simple
        { self.action => self.auditable }
    end

    #
    # @return   [String]    unique link ID
    #
    def id
        #self.action + auditable.keys.reject { |name| name.include?( seed ) }.sort.to_s
        query_vars = self.class.parse_query_vars( self.action )
        "#{@audit_id_url}::#{self.method}::#{query_vars.merge( self.auditable ).keys.sort.to_s}"
    end

    #
    # @return   [String]
    #   Absolute URL with a merged version of {#action} and {#auditable} as a query.
    #
    def to_s
        query_vars = self.class.parse_query_vars( self.action )
        uri = uri_parse( self.action )
        uri.query = query_vars.merge( self.auditable ).map { |k, v| "#{k}=#{v}" }.join( '&' )
        uri.to_s
    end

    # @return [String]  'link'
    def type
        Arachni::Module::Auditor::Element::LINK
    end

    #
    # Returns an array of links based on HTTP response.
    #
    # @param   [Typhoeus::Response]    response
    #
    # @return   [Array<Link>]
    #
    def self.from_response( response )
        url = response.effective_url
        [new( url, parse_query_vars( url ) )] | from_document( url, response.body )
    end

    #
    # Returns an array of links from a document.
    #
    # @param    [String]    url     request URL
    # @param    [String, Nokogiri::HTML::Document]    document
    #
    # @return   [Array<Link>]
    #
    def self.from_document( url, document )
        document = Nokogiri::HTML( document.to_s ) if !document.is_a?( Nokogiri::HTML::Document )
        base_url =  begin
            document.search( '//base[@href]' )[0]['href']
        rescue
            url
        end

        document.search( '//a' ).map do |link|
            c_link = {}
            c_link['href'] = to_absolute( link['href'], base_url )
            next if !c_link['href']
            next if skip_path?( c_link['href'] )

            new( url, c_link['href'] )
        end.compact
    end

    #
    # Extracts variables and their values from a URL query.
    #
    # @param    [String]    url
    #
    # @return   [Hash]    name=>value pairs
    #
    def self.parse_query_vars( url )
        return {} if !url

        query = uri_parse( url ).query
        return {} if !query || query.empty?

        var_hash = {}
        query.split( '&' ).each do |pair|
            name, value = pair.split( '=' )

            #next if value == seed
            var_hash[name] = value
        end

        var_hash
    end

    # @see Base#action=
    def action=( url )
        v = super( url )
        @audit_id_url = self.action.split( '?', 2 ).first
        v
    end

    def audit_id( injection_str = '', opts = {} )
        vars = auditable.keys.sort.to_s

        str = ''
        str << "#{@auditor.fancy_name}:" if !opts[:no_auditor] && !orphan?

        str << "#{@audit_id_url}:" + "#{self.type}:#{vars}"
        str << "=#{injection_str.to_s}" if !opts[:no_injection_str]
        str << ":timeout=#{opts[:timeout]}" if !opts[:no_timeout]

        str
    end

    private
    def http_request( opts, &block )
        http.get( @action, opts, &block )
    end

end
