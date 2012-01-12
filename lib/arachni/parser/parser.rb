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

opts = Arachni::Options.instance
require 'webrick'
require opts.dir['lib'] + 'parser/elements'
require opts.dir['lib'] + 'parser/page'
require opts.dir['lib'] + 'module/utilities'
require opts.dir['lib'] + 'component_manager'

#
# Analyzer class
#
# Analyzes HTML code extracting forms, links and cookies
# depending on user opts.<br/>
#
# It grabs <b>all</b> element attributes not just URLs and variables.<br/>
# All URLs are converted to absolute and URLs outside the domain are ignored.<br/>
#
# === Forms
# Form analysis uses both regular expressions and the Nokogiri parser<br/>
# in order to be able to handle badly written HTML code, such as not closed<br/>
# tags and tag overlaps.
#
# In order to ease audits, in addition to parsing forms into data structures<br/>
# like "select" and "option", all auditable inputs are put under the<br/>
# "auditable" key.
#
# === Links
# Links are extracted using the Nokogiri parser.
#
# === Cookies
# Cookies are extracted from the HTTP headers and parsed by WEBrick::Cookie
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2.2
#
class Parser
    include Arachni::UI::Output
    include Arachni::Module::Utilities

    module Extractors
        #
        # Base Spider parser class for modules.
        #
        # The aim of such modules is to extract paths from a webpage for the Spider to follow.
        #
        #
        # @author: Tasos "Zapotek" Laskos
        #                                      <tasos.laskos@gmail.com>
        #                                      <zapotek@segfault.gr>
        # @version: 0.1
        # @abstract
        #
        class Paths

            #
            # This method must be implemented by all modules and must return an array
            # of paths as plain strings
            #
            # @param    [Nokogiri]  Nokogiri document
            #
            # @return   [Array<String>]  paths
            #
            def run( doc )
            end

        end
    end

    #
    # @return    [String]    the url of the page
    #
    attr_accessor :url

    #
    # Options instance
    #
    # @return    [Options]
    #
    attr_reader :opts

    #
    # Constructor <br/>
    # Instantiates Analyzer class with user options.
    #
    # @param  [Options] opts
    #
    def initialize( opts, res )
        @opts = opts

        @code = res.code
        @url  = url_sanitize( res.effective_url )
        @html = res.body
        @response_headers = res.headers_hash

        @doc   = nil
        @paths = nil
    end

    #
    # Runs the Analyzer and extracts forms, links and cookies
    #
    # @return [Page]
    #
    def run

        # non text files won't contain any auditable elements
        if !text?
            return Page.new( {
                :code        => @code,
                :url         => @url,
                :query_vars  => link_vars( @url ),
                :html        => @html,
                :headers     => [],
                :response_headers     => @response_headers,
                :paths       => [],
                :forms       => [],
                :links       => [],
                :cookies     => [],
                :cookiejar   => []
            } )
        end


        cookies_arr = cookies
        cookies_arr = merge_with_cookiejar( cookies_arr.flatten.uniq )

        jar = {}
        jar = @opts.cookies = Arachni::HTTP.parse_cookiejar( @opts.cookie_jar ) if @opts.cookie_jar

        preped = {}
        cookies_arr.each{ |cookie| preped.merge!( cookie.simple ) }

        jar = preped.merge( jar )

        c_links = links

        if !( vars = link_vars( @url ) ).empty?
            url = to_absolute( @url )
            c_links << Arachni::Parser::Element::Link.new( url, {
                'href' => url,
                'vars' => vars
            } )
        end

        return Page.new( {
            :code        => @code,
            :url         => @url,
            :query_vars  => link_vars( @url ),
            :html        => @html,
            :headers     => headers(),
            :response_headers     => @response_headers,
            :paths       => paths(),
            :forms       => @opts.audit_forms ? forms() : [],
            :links       => @opts.audit_links ? c_links : [],
            :cookies     => merge_with_cookiestore( merge_with_cookiejar( cookies_arr ) ),
            :cookiejar   => jar
        } )

    end

    def text?
        type = Arachni::HTTP.content_type( @response_headers )
        return false if !type
        return type.to_s.substring?( 'text' )
    end

    def doc
      return @doc if @doc
      @doc = Nokogiri::HTML( @html ) if @html rescue nil
    end

    def merge_with_cookiestore( cookies )

        @cookiestore ||= []

        if @cookiestore.empty?
            @cookiestore = cookies
        else
            tmp = {}
            @cookiestore.each {
                |cookie|
                tmp.merge!( cookie.simple )
            }

            cookies.each {
                |cookie|
                tmp.merge!( cookie.simple )
            }

            @cookiestore = tmp.map {
                |name, value|
                Element::Cookie.new( @url, {
                    'name'    => name,
                    'value'   => value
                } )
            }
        end

        return @cookiestore

    end

    #
    # Merges 'cookies' with the cookiejar and returns it as an array
    #
    # @param    [Array<Hash>]  cookies
    #
    # @return   [Array<Element::Cookie>]  the merged cookies
    #
    def merge_with_cookiejar( cookies )
        return cookies if !@opts.cookies

        @opts.cookies.each_pair {
            |name, value|
            cookies << Element::Cookie.new( @url,
                {
                    'name'    => name,
                    'value'   => value
                } )
        }

        return cookies
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
        headers_arr  = []
        {
            'accept'          => 'text/html,application/xhtml+xml,application' +
                '/xml;q=0.9,*/*;q=0.8',
            'accept-charset'  => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
            'accept-language' => 'en-gb,en;q=0.5',
            'accept-encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'from'       => @opts.authed_by || '',
            'user-agent' => @opts.user_agent || '',
            'referer'    => @url,
            'pragma'     => 'no-cache'
        }.each {
            |k,v|
            headers_arr << Element::Header.new( @url, { k => v } )
        }

        return headers_arr
    end

    # TODO: Add support for radio buttons.
    #
    # Extracts forms from HTML document
    #
    # @see #form_attrs
    # @see #form_textareas
    # @see #form_selects
    # @see #form_inputs
    # @see #merge_select_with_input
    #
    # @param  [String] html
    #
    # @return [Array<Element::Form>] array of forms
    #
    def forms( html = nil )

        elements = []

        begin
            html = html || @html.clone
            #
            # This imitates Firefox's behavior when it comes to
            # broken/unclosed form tags
            #

            # get properly closed forms
            forms = html.scan( /<form(.*?)<\/form>/ixm ).flatten

            # now remove them from html...
            forms.each { |form| html.gsub!( form, '' ) }

            # and get unclosed forms.
            forms |= html.scan( /<form (.*)(?!<\/form>)/ixm ).flatten

        rescue Exception => e
            return elements
        end

        i = 0
        forms.each {
            |form|

            elements[i] = Hash.new
            elements[i]['attrs']    = form_attrs( form )

            if( !elements[i]['attrs'] || !elements[i]['attrs']['action'] )
                action = @url.to_s
            else
                action = url_sanitize( elements[i]['attrs']['action'] )
            end
            action = uri_encode( action ).to_s

            elements[i]['attrs']['action'] = to_absolute( action.clone ).to_s

            if( !elements[i]['attrs']['method'] )
                elements[i]['attrs']['method'] = 'post'
            else
                elements[i]['attrs']['method'] =
                    elements[i]['attrs']['method'].downcase
            end

            next if skip?( elements[i]['attrs']['action'] )

            elements[i]['textarea'] = form_textareas( form )
            elements[i]['select']   = form_selects( form )
            elements[i]['input']    = form_inputs( form )

            # merge the form elements to make auditing easier
            elements[i]['auditable'] =
                elements[i]['input'] | elements[i]['textarea']

            elements[i]['auditable'] =
                merge_select_with_input( elements[i]['auditable'],
                    elements[i]['select'] )

            elements[i] = Element::Form.new( @url, elements[i] )


            i += 1
        }

        elements.reject {
            |form|
            !form.is_a?( Element::Form ) || form.auditable.empty?
        }
    end

    #
    # Extracts links from HTML document
    #
    # @see #link_vars
    #
    # @param  [String] html
    #
    # @return [Array<Element::Link>] of links
    #
    def links

        link_arr = []
        elements_by_name( 'a' ).each_with_index {
            |link|

            link['href'] = to_absolute( link['href'] )

            if !link['href'] then next end
            next if skip?( link['href'] )

            link['vars'] = {}
            link_vars( link['href'] ).each_pair {
                |key, val|
                begin
                    link['vars'][key] = url_sanitize( val )
                rescue
                    link['vars'][key] = val
                end
            }

            link['href'] = url_sanitize( link['href'] )

            link_arr << Element::Link.new( @url, link )

        }

        return link_arr
    end

    #
    # Extracts cookies from an HTTP headers
    #
    # @param  [String] headers  HTTP headers
    # @param  [String] html     the HTML code of the page
    #
    # @return [Array<Element::Cookie>] of cookies
    #
    def cookies

        cookies_arr = []
        cookies     = []

        begin
            doc.search( "//meta[@http-equiv]" ).each {
                |elem|

                next if elem['http-equiv'].downcase != 'set-cookie'
                k, v = elem['content'].split( ';' )[0].split( '=', 2 )
                cookies_arr << Element::Cookie.new( @url, { 'name' => k, 'value' => v } )
            }
        rescue Exception => e
            # ap e
            # ap e.backtrace
        end


        # don't ask me why....
        if @response_headers.to_s.downcase.substring?( 'set-cookie' )
            begin
                cookies << ::WEBrick::Cookie.parse_set_cookies( @response_headers['Set-Cookie'].to_s )
                cookies << ::WEBrick::Cookie.parse_set_cookies( @response_headers['set-cookie'].to_s )
            rescue Exception => e
                # ap e
                # ap e.backtrace
                return cookies_arr
            end
        end

        cookies.flatten.uniq.each_with_index {
            |cookie, i|
            cookies_arr[i] = Hash.new

            cookie.instance_variables.each {
                |var|
                value = cookie.instance_variable_get( var ).to_s
                value.strip!

                key = normalize_name( var )
                val = value.gsub( /[\"\\\[\]]/, '' )

                next if val == seed
                cookies_arr[i][key] = val
            }

            # cookies.reject!{ |cookie| cookie['name'] == cookies_arr[i]['name'] }

            cookies_arr[i] = Element::Cookie.new( @url, cookies_arr[i] )
        }
        cookies_arr.flatten!
        return cookies_arr
    end

    def dir( url )
        URI( File.dirname( URI( url.to_s ).path ) + '/' )
    end

    #
    # Array of distinct links to follow
    #
    # @return   [Array<URI>]
    #
    def paths
      return @paths unless @paths.nil?
      @paths = []
      return @paths if !doc

      @paths = run_extractors
      return @paths
    end

    #
    # Extracts variables and their values from a link
    #
    # @see #links
    #
    # @param [String]    link
    #
    # @return [Hash]    name=>value pairs
    #
    def link_vars( link )
        if !link then return {} end

        var_string = link.split( /\?/ )[1]
        if !var_string then return {} end

        var_hash = Hash.new
        var_string.split( /&/ ).each {
            |pair|
            name, value = pair.split( /=/ )

            next if value == seed
            var_hash[name] = value
        }

        var_hash

    end

    #
    # Converts relative URL *link* into an absolute URL based on the
    # location of the page
    #
    # @param [String] link
    #
    # @return [String]
    #
    def to_absolute( link )

        begin
            link = normalize_url( link )
            if uri_parser.parse( link ).host
                return link
            end
        rescue Exception => e
            # ap e
            # ap e.backtrace
            return nil
        end

        begin
            # remove anchor
            link = uri_encode( link.to_s.gsub( /#[a-zA-Z0-9_-]*$/,'' ) )

            if url = base
                base_url = uri_parser.parse( url )
            else
                base_url = uri_parser.parse( @url )
            end

            relative = uri_parser.parse( link )
            absolute = base_url.merge( relative )

            absolute.path = '/' if absolute.path && absolute.path.empty?

            return absolute.to_s
        rescue Exception => e
            # ap e
            # ap e.backtrace
            return nil
        end
    end


    def base
        begin
            tmp = doc.search( '//base[@href]' )
            return tmp[0]['href'].dup
        rescue
            return
        end
    end


    def too_deep?( url )
        if @opts.depth_limit > 0 && (@opts.depth_limit + 1) <= URI(url.to_s).path.count( '/' )
            return true
        else
            return false
        end
    end

    #
    # Returns +true+ if *uri* is in the same domain as the page, returns
    # +false+ otherwise
    #
    def in_domain?( uri )

        curi = URI.parse( normalize_url( uri.to_s ) )

        if( @opts.follow_subdomains )
            return extract_domain( curi ) ==  extract_domain( URI( @url.to_s ) )
        end

        return curi.host == URI.parse( normalize_url( @url.to_s ) ).host
    end

    #
    # Extracts the domain from a URI object
    #
    # @param [URI] url
    #
    # @return [String]
    #
    def extract_domain( url )

        if !url.host then return false end

        splits = url.host.split( /\./ )

        if splits.length == 1 then return true end

        splits[-2] + "." + splits[-1]
    end

    def exclude?( url )
        @opts.exclude.each {
            |pattern|
            return true if url.to_s =~ pattern
        }

        return false
    end

    def include?( url )
        return true if @opts.include.empty?

        @opts.include.each {
            |pattern|
            pattern = Regexp.new( pattern ) if pattern.is_a?( String )
            return true if url.to_s =~ pattern
        }
        return false
    end

    def skip?( path )
        return true if !path

        begin
            return true if !include?( path )
            return true if exclude?( path )
            return true if too_deep?( path )
            return true if !in_domain?( path )
        rescue
            true
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
            @@manager ||=
                ::Arachni::ComponentManager.new( @opts.dir['path_extractors'], Extractors )

            return @@manager.available.map {
                |name|
                exception_jail( false ){ @@manager[name].new.run( doc ) }
            }.flatten.uniq.compact.
            map { |path| to_absolute( url_sanitize( path ) ) }.
            reject { |path| skip?( path ) }

        rescue ::Exception => e
            print_error( e.to_s )
            print_error_backtrace( e )
        end
    end

    #
    # Merges an array of form inputs with an array of form selects
    #
    # @see #forms
    #
    # @param    [Array]  form inputs
    # @param    [Array]  form selects
    #
    # @return   [Array]  merged array
    #
    def merge_select_with_input( inputs, selects )

        new_arr = []
        inputs.each {
            |input|
            new_arr << input
        }

        i = new_arr.size
        selects.each {
            |select|

            begin
                select['attrs']['value'] = select['options'][0]['value']
            rescue
            end
            new_arr << select['attrs']
        }

        new_arr
    end


    #
    # Parses the attributes inside the <form ....> tag
    #
    # @see #forms
    # @see #attrs_from_tag
    #
    # @param  [String] form   HTML code for the form tag
    #
    # @return [Array<Hash<String, String>>]
    #
    def form_attrs( form )
        form_attr_html = form.scan( /(.*?)>/ixm )
        attrs_from_tag( 'form', '<form ' + form_attr_html[0][0] + '>' )[0]
    end


    #
    # Extracts HTML select elements, their attributes and their options
    #
    # @see #forms
    # @see #form_selects_options
    #
    # @param    [String]    HTML
    #
    # @return    [Array]    array of select elements
    #
    def form_selects( html )
        selects = html.scan( /<select(.*?)>/ixm )

        elements = []
        selects.each_with_index {
            |select, i|
            elements[i] = Hash.new
            elements[i]['options'] =  form_selects_options( html )

            elements[i]['attrs'] =
                attrs_from_tag( 'select',
                    '<select ' + select[0] + '/>' )[0]

        }

        elements
    end

    #
    # Extracts HTML option elements and their attributes
    # from select elements
    #
    # @see #forms
    # @see #form_selects
    #
    # @param    [String]    HTML selects
    #
    # @return    [Array]    array of option elements
    #
    def form_selects_options( html )
        options = html.scan( /<option(.*?)>/ixm )

        elements = []
        options.each_with_index {
            |option, i|
            elements[i] =
                attrs_from_tag( 'option',
                    '<option ' + option[0] + '/>' )[0]

        }

        elements
    end

    #
    # Extracts HTML textarea elements and their attributes
    # from forms
    #
    # @see #forms
    #
    # @param    [String]    HTML
    #
    # @return    [Array]    array of textarea elements
    #
    def form_textareas( html )
        inputs = html.scan( /<textarea(.*?)>/ixm )

        elements = []
        inputs.each_with_index {
            |input, i|
            elements[i] =
                attrs_from_tag( 'textarea',
                    '<textarea ' + input[0] + '/>' )[0]
        }
        elements
    end

    #
    # Parses the attributes of input fields
    #
    # @see #forms
    #
    # @param  [String] html   HTML code for the form tag
    #
    # @return [Hash<Hash<String, String>>]
    #
    def form_inputs( html )
        inputs = html.scan( /<input(.*?)>/ixm )

        elements = []
        inputs.each_with_index {
            |input, i|
            elements[i] =
                attrs_from_tag( 'input',
                    '<input ' + input[0] + '/>' )[0]
        }

        elements
    end

    #
    # Gets attributes from HTML code of a tag
    #
    # @param  [String] tag    tag name (a, form, input)
    # @param  [String] html   HTML code for the form tag
    #
    # @return [Array<Hash<String, String>>]
    #
    def attrs_from_tag( tag, html )

        elements = []
        Nokogiri::HTML( html ).search( tag ).each_with_index {
            |element, i|

            elements[i] = Hash.new

            element.each {
                |attribute|
                next if attribute[1] == seed
                elements[i][attribute[0].downcase] = attribute[1]
            }

        }
        elements
    end

    # Extracts elements by name from HTML document
    #
    # @param [String] name 'form', 'a', 'div', etc.
    # @param  [String] html
    #
    # @return [Array<Hash <String, String> >] of elements
    #
    def elements_by_name( name )

        elements = []
        doc.search( name ).each_with_index do |input, i|

            elements[i] = Hash.new
            input.each {
                |attribute|
                elements[i][attribute[0]] = attribute[1]
            }

            input.children.each {
                |child|
                child.each{
                    |attribute|
                    elements[i][attribute[0]] = attribute[1]
                }
            }

        end rescue []

        return elements
    end

    def normalize_name( name )
        name.to_s.gsub( /@/, '' )
    end
end
end
