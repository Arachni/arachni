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

    def initialize( url, raw = {} )
        super( url, raw )

        self.action = @raw['href'] || @raw[:href] || @raw['action'] || @raw[:action] || self.url
        self.method = 'get'

        self.auditable = @raw['vars'] || @raw[:vars] || @raw['inputs'] || @raw[:inputs]
        self.auditable ||= {}

        @orig = self.auditable.dup
        @orig.freeze
    end

    def simple
        { @action => @auditable }
    end

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
        from_document( response.effective_url, response.body )
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
        base_url = url
        begin
            base_url = document.search( '//base[@href]' )[0]['href']
        rescue
            base_url = url
        end

        utilities = Arachni::Module::Utilities
        document.search( '//a' ).map do |link|
            c_link = {}
            c_link['href'] = utilities.to_absolute( link['href'], base_url )

            next if !c_link['href']
            next if utilities.skip_path?( c_link['href'] )

            c_link['vars'] = {}
            parse_query_vars( c_link['href'] ).each_pair do |key, val|
                begin
                    c_link['vars'][key] = utilities.url_sanitize( val )
                rescue
                    c_link['vars'][key] = val
                end
            end

            c_link['href'] = utilities.url_sanitize( c_link['href'] )
            new( url, c_link )
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
        return {}  if !url

        var_string = url.split( /\?/ )[1]
        return {} if !var_string

        var_hash = {}
        var_string.split( /&/ ).each do |pair|
            name, value = pair.split( /=/ )

            next if value == Arachni::Module::Utilities.seed
            var_hash[name] = value
        end

        var_hash
    end

    def action=( url )
        v = super( url )
        @audit_id_url = self.action.gsub( /\?.*/, '' )
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
