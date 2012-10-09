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

module Arachni

lib = Options.dir['lib']

# load all available element types
Dir.glob( lib + 'element/*.rb' ).each { |f| require f }

require lib + 'page'
require lib + 'utilities'
require lib + 'component/manager'

#
# Analyzer class
#
# Analyzes HTML code extracting forms, links and cookies
# depending on user opts.
#
# It grabs <b>all</b> element attributes not just URLs and variables.
# All URLs are converted to absolute and URLs outside the domain are ignored.
#
# === Forms
# Form analysis uses both regular expressions and the Nokogiri parser
# in order to be able to handle badly written HTML code, such as not closed
# tags and tag overlaps.
#
# In order to ease audits, in addition to parsing forms into data structures
# like "select" and "option", all auditable inputs are put under the "auditable" key.
#
# === Links
# Links are extracted using the Nokogiri parser.
#
# === Cookies
# Cookies are extracted from the HTTP headers and parsed by WEBrick::Cookie
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
#
class Parser
    include UI::Output
    include Utilities

    module Extractors
        #
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        #
        # @abstract
        #
        class Base

            #
            # This method must be implemented by all modules and must return an array
            # of paths as plain strings
            #
            # @param    [Nokogiri]  doc   Nokogiri document
            #
            # @return   [Array<String>]  paths
            #
            def run( doc )
            end

        end
    end

    alias :skip? :skip_path?

    #
    # @return    [String]    the url of the page
    #
    attr_reader :url

    #
    # Options instance
    #
    # @return    [Options]
    #
    attr_reader :opts

    #
    # Instantiates Analyzer class with user options.
    #
    # @param  [Typhoeus::Responses, Array<Typhoeus::Responses>] res
    # @param  [Options] opts
    #
    def initialize( res, opts = Options )
        @opts = opts

        if res.is_a? Array
            @secondary_responses = res[1..-1]
            @secondary_responses.compact! if @secondary_responses
            res = res.shift
        end

        @code     = res.code
        self.url  = res.effective_url
        @html     = res.body
        @response = res

        @response_headers = res.headers_hash

        @doc   = nil
        @paths = nil
    end

    def url=( str )
        @url = normalize_url( str )
    end

    #
    # Converts a relative URL to an absolute one.
    #
    # @return   [String]    absolute URL
    #
    def to_absolute( relative_url )
        if url = base
            base_url = url
        else
            base_url = @url
        end
        super( relative_url, base_url )
    end

    #
    # @param    [String]    url     to check
    #
    # @return   [Bool]    true if URL is within domain limits, false if not
    #
    def path_in_domain?( url )
        super( url, @url )
    end

    #
    # Runs the Analyzer and extracts forms, links and cookies
    #
    # @return [Page]
    #
    def page
        req_method = 'get'
        begin
            req_method = @response.request.method.to_s
        rescue
        end

        self_link = Link.new( @url, inputs: link_vars( @url ) )

        # non text files won't contain any auditable elements
        if !text?
            return Page.new(
                code:             @code,
                url:              @url,
                method:           req_method,
                query_vars:       self_link.auditable,
                body:             @html,
                request_headers:  @response.request.headers,
                response_headers: @response_headers,
                text:             false
            )
        end

        # extract cookies from the response
        c_cookies = cookies

        # make a list of the response cookie names
        cookie_names = c_cookies.map { |c| c.name }

        from_jar = []

        # if there's a Netscape cookiejar file load cookies from it but only new ones,
        # i.e. only if they weren't in the response
        if @opts.cookie_jar
            from_jar |= cookies_from_file( @url, @opts.cookie_jar )
                .reject { |c| cookie_names.include?( c.name ) }
        end

        # if we somehow have any runtime configuration cookies load them too
        # but only if they haven't already been seen
        if @opts.cookies && !@opts.cookies.empty?
            from_jar |= @opts.cookies.reject { |c| cookie_names.include?( c.name ) }
        end

        # grab cookies from the HTTP cookiejar and filter out old ones, as usual
        from_http_jar = HTTP.instance.cookie_jar.cookies.reject do |c|
            cookie_names.include?( c.name )
        end

        # these cookies are to be audited and thus are dirty and anarchistic
        # so they have to contain even cookies completely irrelevant to the
        # current page, i.e. it contains all cookies that have been observed
        # from the beginning of the scan
        cookies_to_be_audited = (c_cookies | from_jar | from_http_jar).map do |c|
            dc = c.dup
            dc.action = @url
            dc
        end

        Page.new(
            code:             @code,
            url:              @url,
            query_vars:       self_link.auditable,
            method:           req_method,
            body:             @html,

            request_headers:  @response.request.headers,
            response_headers: @response_headers,

            document:         doc,

            # all paths seen in the page
            paths:            paths,
            forms:            forms,

            # all href attributes from 'a' elements
            links:            links | [self_link],

            cookies:          cookies_to_be_audited,
            headers:          headers,

            # this is the page cookiejar, each time the page is to be audited
            # by a module the cookiejar of the HTTP class will be updated
            # with the cookies specified here
            cookiejar:        c_cookies | from_jar,

            text:             true
        )
    end
    alias :run :page

    def text?
        type = @response.content_type
        return false if !type
        type.to_s.substring?( 'text' )
    end

    def doc
        return @doc if @doc
        @doc = Nokogiri::HTML( @html ) if text? rescue nil
    end

    #
    # Returns a list of valid auditable HTTP header fields.
    #
    # It's more of a placeholder method, it doesn't actually analyze anything.<br/>
    # It's a long shot that any of these will be vulnerable but better
    # be safe than sorry.
    #
    # @return    [Hash]    HTTP header fields
    #
    def headers
        {
            'Accept'          => 'text/html,application/xhtml+xml,application' +
                '/xml;q=0.9,*/*;q=0.8',
            'Accept-Charset'  => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
            'Accept-Language' => 'en-gb,en;q=0.5',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'From'       => @opts.authed_by  || '',
            'User-Agent' => @opts.user_agent || '',
            'Referer'    => @url,
            'Pragma'     => 'no-cache'
        }.map { |k, v| Header.new( @url, { k => v } ) }
    end

    #
    # Extracts forms from HTML document
    #
    # @param  [String] html
    #
    # @return [Array<Element::Form>] array of forms
    #
    def forms( html = nil )
        return [] if !text? && !html

        f = Form.from_document( @url, html || doc )

        if @secondary_responses
            @secondary_responses.each do |response|
                next if response.body.to_s.empty?

                Form.from_document( @url, response.body ).each do |form2|
                    f.each do |form|
                        next if form.auditable.keys.sort != form2.auditable.keys.sort
                        form.auditable.each do |k, v|
                            if v != form2.auditable[k] && form.field_type_for( k ) == 'hidden'
                                form.nonce_name = k
                            end
                        end
                    end
                end
            end
        end

        f
    end

    #
    # Extracts links from HTML document
    #
    # @param  [String] html
    #
    # @return [Array<Element::Link>] of links
    #
    def links( html = nil )
        return [] if !text? && !html

        if !(vars = link_vars( @url )).empty? || @response.redirection?
            [Link.new( @url, vars )]
        else
            []
        end | Link.from_document( @url, html || doc )
    end

    #
    # Extracts variables and their values from a link
    #
    # @see #links
    #
    # @param    [String]    url
    #
    # @return   [Hash]    name=>value pairs
    #
    def link_vars( url )
        Link.parse_query_vars( url )
    end

    #
    # Extracts cookies from an HTTP headers and the response body
    #
    # @return   [Array<Element::Cookie>]
    #
    def cookies
        ( Cookie.from_document( @url, doc ) |
          Cookie.from_headers( @url, @response_headers ) )
    end

    #
    # Array of distinct links to follow
    #
    # @return   [Array<String>]
    #
    def paths
      return @paths unless @paths.nil?
      @paths = []
      return @paths if !doc

      @paths = run_extractors
    end

    #
    # @return   [String]    base href if there is one
    #
    def base
        @base ||= begin
            doc.search( '//base[@href]' ).first['href']
        rescue
        end
    end

    private

    #
    # Runs all Spider (path extraction) modules and returns an array of paths
    #
    # @return   [Array]   paths
    #
    def run_extractors
        begin
            @@manager ||= Component::Manager.new( @opts.dir['path_extractors'], Extractors )

            return @@manager.available.map do |name|
                exception_jail( false ){ @@manager[name].new.run( doc ) }
            end.flatten.uniq.compact.
            map { |path| to_absolute( path ) }.compact.uniq.
            reject { |path| skip?( path ) }
        rescue ::Exception => e
            print_error( e.to_s )
            print_error_backtrace( e )
        end
    end

end
end
