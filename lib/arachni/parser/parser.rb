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
require opts.dir['lib'] + 'ruby/webrick'
require opts.dir['lib'] + 'parser/element/link'
require opts.dir['lib'] + 'parser/element/form'
require opts.dir['lib'] + 'parser/element/cookie'
require opts.dir['lib'] + 'parser/element/header'
require opts.dir['lib'] + 'parser/page'
require opts.dir['lib'] + 'module/utilities'
require opts.dir['lib'] + 'component_manager'

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
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#
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
        # @author Tasos "Zapotek" Laskos
        #                                      <tasos.laskos@gmail.com>
        #
        # @version 0.1
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
        @response = res

        @doc   = nil
        @paths = nil
    end

    def to_absolute( relative_url )
        if url = base
            base_url = url
        else
            base_url = @url
        end
        super( base_url, relative_url )
    end

    def skip?( path )
        skip_path?( path )
    end

    #
    # Runs the Analyzer and extracts forms, links and cookies
    #
    # @return [Page]
    #
    def run
        req_method = 'get'
        begin
            req_method = @response.request.method.to_s
        rescue
        end

        self_link = Arachni::Parser::Element::Link.new( @url, inputs: link_vars( @url ) )

        # non text files won't contain any auditable elements
        if !text?
            return Page.new(
                :code        => @code,
                :url         => @url,
                :method      => req_method,
                :query_vars  => self_link.auditable,
                :html        => @html,
                :response_headers => @response_headers
            )
        end

        cookies_arr = cookies
        cookies_arr = merge_with_cookiejar( cookies_arr.flatten.uniq )

        jar = {}
        jar = @opts.cookies = Arachni::HTTP.parse_cookiejar( @opts.cookie_jar ) if @opts.cookie_jar

        preped = {}
        cookies_arr.each{ |cookie| preped.merge!( cookie.simple ) }

        return Page.new(
            :code        => @code,
            :url         => @url,
            :query_vars  => self_link.auditable,
            :method      => req_method,
            :html        => @html,
            :response_headers => @response_headers,
            :paths       => paths(),
            :forms       => forms(),
            :links       => links() | [self_link],
            :cookies     => merge_with_cookiestore( cookies_arr ),
            :headers     => headers(),
            :cookiejar   => preped.merge( jar )
        )
    end

    def text?
        type = @response.content_type
        return false if !type
        return type.to_s.substring?( 'text' )
    end

    def doc
        return @doc if @doc
        @doc = Nokogiri::HTML( @html ) if @html rescue nil
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
            'accept'          => 'text/html,application/xhtml+xml,application' +
                '/xml;q=0.9,*/*;q=0.8',
            'accept-charset'  => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
            'accept-language' => 'en-gb,en;q=0.5',
            'accept-encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'from'       => @opts.authed_by || '',
            'user-agent' => @opts.user_agent || '',
            'referer'    => @url,
            'pragma'     => 'no-cache'
        }.map { |k, v| Element::Header.new( @url, { k => v } ) }
    end

    #
    # Extracts forms from HTML document
    #
    # @param  [String] html
    #
    # @return [Array<Element::Form>] array of forms
    #
    def forms( html = nil )
        Element::Form.from_document( @url, html || doc )
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

            next if !link['href']
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
    # Extracts cookies from an HTTP headers and the response body
    #
    # @return   [Array<Element::Cookie>]
    #
    def cookies
        ( Element::Cookie.from_document( @url, doc ) |
          Element::Cookie.from_headers( @url, @response_headers ) )
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
        return {}  if !link

        var_string = link.split( /\?/ )[1]
        return {} if !var_string

        var_hash = {}
        var_string.split( /&/ ).each {
            |pair|
            name, value = pair.split( /=/ )

            next if value == seed
            var_hash[name] = value
        }

        var_hash
    end

    def base
        begin
            tmp = doc.search( '//base[@href]' )
            return tmp[0]['href'].dup
        rescue
            return
        end
    end

    private

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

        already_set = cookies.map { |c| c.simple.keys.first }
        @opts.cookies.each_pair {
            |name, value|
            next if already_set.include?( name )

            cookies << Element::Cookie.new( @url,
                {
                    'name'    => name,
                    'value'   => value
                } )
        }

        return cookies
    end

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
