=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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

# Load all available element types.
Dir.glob( lib + 'element/*.rb' ).each { |f| require f }

require lib + 'page'
require lib + 'utilities'
require lib + 'component/manager'

#
# HTML Parser
#
# Analyzes HTML code extracting forms, links and cookies depending on user opts.
#
# ignored.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
#
class Parser
    include UI::Output
    include Utilities

    module Extractors

        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        # @abstract
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

    # @return    [String]    The url of the page.
    attr_reader :url

    # @return    [Options]  Options instance.
    attr_reader :opts

    #
    # @param  [Typhoeus::Responses, Array<Typhoeus::Responses>] res
    #   Response(s) to analyze and parse into a {Page}. By providing multiple
    #   responses the parser will be able to perform some preliminary differential
    #   analysis and identify nonce tokens in inputs.
    #
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
        @url = normalize_url( uri_decode( str ) )
        @url = normalize_url( str ) if !@url
        @url
    end

    #
    # Converts a relative URL to an absolute one.
    #
    # @param    [String]    relative_url    URL to convert to absolute.
    #
    # @return   [String]    Absolute URL.
    #
    def to_absolute( relative_url )
        if url = base
            base_url = url
        else
            base_url = @url
        end
        super( relative_url, base_url )
    end

    # @return [Page]
    #   Parsed page object based on the given options and HTTP responses.
    def page
        req_method = @response.request ? @response.request.method.to_s : 'get'

        self_link = Link.new( @url, inputs: link_vars( @url ) )

        # Non text files won't contain any auditable elements.
        if !text?
            page = Page.new(
                code:             @code,
                url:              @url,
                method:           req_method,
                query_vars:       self_link.auditable,
                body:             @html,
                request_headers:  @response.request ? @response.request.headers : {},
                response_headers: @response_headers,
                text:             false,
                links:            [self_link]
            )
            Platform::Manager.fingerprint( page ) if Options.fingerprint?
            return page
        end

        # Extract cookies from the response.
        c_cookies = cookies

        # Make a list of the response cookie names.
        cookie_names = c_cookies.map { |c| c.name }

        from_jar = []

        # If there's a Netscape cookiejar file load cookies from it but only
        # new ones, i.e. only if they weren't already in the response.
        if @opts.cookie_jar.is_a?( String ) && File.exists?( @opts.cookie_jar )
            from_jar |= cookies_from_file( @url, @opts.cookie_jar )
                .reject { |c| cookie_names.include?( c.name ) }
        end

        # If we somehow have runtime configuration cookies load them too, but
        # only if they haven't already been seen.
        if @opts.cookies && !@opts.cookies.empty?
            from_jar |= @opts.cookies.reject { |c| cookie_names.include?( c.name ) }
        end

        # grab cookies from the HTTP cookiejar and filter out old ones, as usual
        from_http_jar = HTTP.instance.cookie_jar.cookies.reject do |c|
            cookie_names.include?( c.name )
        end

        # These cookies are to be audited and thus are dirty and anarchistic,
        # so they have to contain even cookies completely irrelevant to the
        # current page. I.e. it contains all cookies that have been observed
        # since the beginning of the scan
        cookies_to_be_audited = (c_cookies | from_jar | from_http_jar).map do |c|
            dc = c.dup
            dc.action = @url
            dc
        end

        page = Page.new(
            code:             @code,
            url:              @url,
            query_vars:       self_link.auditable,
            method:           req_method,
            body:             @html,

            request_headers:  @response.request ? @response.request.headers : {},
            response_headers: @response_headers,

            document:         doc,

            # All paths seen in the page.
            paths:            paths,
            forms:            forms,

            # All `href` attributes from `a` elements.
            links:            links | [self_link],

            cookies:          cookies_to_be_audited,
            headers:          headers,

            # This is the page cookiejar, each time the page is to be audited
            # by a module, the cookiejar of the HTTP class will be updated
            # with the cookies specified here.
            cookiejar:        c_cookies | from_jar,

            # Contains text-based data -- i.e. not a binary response.
            text:             true
        )
        Platform::Manager.fingerprint( page ) if Options.fingerprint?
        page
    end
    alias :run :page

    # @return   [Boolean]
    #   `true` if the given HTTP response data are text based, `false` otherwise.
    def text?
        @response.text?
    end

    # @return   [Nokogiri::HTML, nil]
    #   Returns a parsed HTML document from the body of the HTTP response or
    #   `nil` if the response data wasn't {#text? text-based} or the response
    #   couldn't be parsed.
    def doc
        return @doc if @doc
        @doc = Nokogiri::HTML( @html ) if text? rescue nil
    end

    #
    # @note It's more of a placeholder method, it doesn't actually analyze anything.
    #   It's a long shot that any of these will be vulnerable but better be safe
    #   than sorry.
    #
    # @return    [Hash]    List of valid auditable HTTP header fields.
    #
    def headers
        {
            'Accept'          => 'text/html,application/xhtml+xml,application' +
                '/xml;q=0.9,*/*;q=0.8',
            'Accept-Charset'  => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'From'            => @opts.authed_by  || '',
            'User-Agent'      => @opts.user_agent || '',
            'Referer'         => @url,
            'Pragma'          => 'no-cache'
        }.map { |k, v| Header.new( @url, { k => v } ) }
    end

    # @param  [String, Nokogiri::HTML] html
    #   Document to analyze, defaults to {#doc}.
    #
    # @return [Array<Element::Form>]    Forms from `html`.
    def forms( html = nil )
        return [] if !text? && !html

        f = Form.from_document( @url, html || doc )
        return f if !@secondary_responses

        @secondary_responses.each do |response|
            next if response.body.to_s.empty?

            Form.from_document( @url, response.body ).each do |form2|
                f.each do |form|
                    next if "#{form.id}:#{form.name_or_id}" !=
                        "#{form2.id}:#{form2.name_or_id}"

                    form.auditable.each do |k, v|
                        next if !(v != form2.auditable[k] &&
                            form.field_type_for( k ) == 'hidden')

                        form.nonce_name = k
                    end
                end
            end
        end

        f
    end

    # @param  [String, Nokogiri::HTML] html
    #   Document to analyze, defaults to {#doc}.
    #
    # @return [Array<Element::Link>] Links in `html`.
    def links( html = nil )
        return [] if !text? && !html

        if !(vars = link_vars( @url )).empty? || @response.redirection?
            [Link.new( @url, vars )]
        else
            []
        end | Link.from_document( @url, html || doc )
    end

    # @param    [String]    url URL to analyze.
    # @return   [Hash]    Parameters found in `url`.
    def link_vars( url )
        Link.parse_query_vars( url )
    end

    #
    # @return   [Array<Element::Cookie>]
    #   Cookies from HTTP headers and response body.
    def cookies
        ( Cookie.from_document( @url, doc ) |
          Cookie.from_headers( @url, @response_headers ) )
    end

    # @return   [Array<String>] Distinct links to follow.
    def paths
      return @paths unless @paths.nil?
      @paths = []
      return @paths if !doc

      @paths = run_extractors
    end

    # @return   [String]    `base href`, if there is one.
    def base
        @base ||= doc.search( '//base[@href]' ).first['href'] rescue nil
    end

    private

    #
    # Runs all path extraction components and returns an array of paths.
    #
    # @return   [Array<String>]   Paths.
    #
    def run_extractors
        begin
            return self.class.extractors.available.map do |name|
                    exception_jail( false ){ self.class.extractors[name].new.run( doc ) }
                end.flatten.uniq.compact.
                map { |path| to_absolute( path ) }.compact.uniq.
                reject { |path| path.to_s.empty? || skip?( path ) }
        rescue ::Exception => e
            print_error e.to_s
            print_error_backtrace e
        end
    end

    def self.extractors
        @manager ||= Component::Manager.new( Options.dir['path_extractors'], Extractors )
    end

end
end
