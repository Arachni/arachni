=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)
=end

module Arachni

opts = Arachni::Options.instance
require opts.dir['lib'] + 'parser/elements'
require opts.dir['lib'] + 'parser/page'

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
# @version: 0.2
#
class Parser

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

        @url  = res.effective_url
        @html = res.body
        @response_headers = res.headers_hash
    end

    #
    # Runs the Analyzer and extracts forms, links and cookies
    #
    # @return [Page]
    #
    def run

        cookies_arr = cookies
        cookies_arr = merge_with_cookiejar( cookies_arr.flatten.uniq )

        jar = {}
        jar = @opts.cookies = Arachni::HTTP.parse_cookiejar( @opts.cookie_jar ) if @opts.cookie_jar

        preped = {}
        cookies_arr.each{ |cookie| preped.merge!( cookie.simple ) }

        jar = preped.merge( jar )

        return Page.new( {
            :url         => @url,
            :query_vars  => link_vars( @url ),
            :html        => @html,
            :headers     => headers(),
            :response_headers     => @response_headers,
            :forms       => @opts.audit_forms ? forms() : [],
            :links       => @opts.audit_links ? links() : [],
            :cookies     => merge_with_cookiestore( merge_with_cookiejar( cookies_arr ) ),
            :cookiejar   => jar
        } )

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
    def headers( )
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
                action = elements[i]['attrs']['action']
            end
            action = URI.escape( action ).to_s

            elements[i]['attrs']['action'] = to_absolute( action.clone ).to_s

            if( !elements[i]['attrs']['method'] )
                elements[i]['attrs']['method'] = 'post'
            else
                elements[i]['attrs']['method'] =
                    elements[i]['attrs']['method'].downcase
            end

            url = URI.parse( URI.escape( elements[i]['attrs']['action'] ) )
            if !in_domain?( url )
                next
            end

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
            form.auditable.empty?
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
            if( exclude?( link['href'] ) ) then next end
            if( !include?( link['href'] ) ) then next end
            if !in_domain?( URI.parse( link['href'] ) ) then next end

            link['vars'] = link_vars( link['href'] )


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
        rescue
        end

        # don't ask me why....
        if @response_headers.to_s.substring?( 'set-cookie' )
            begin
                cookies << WEBrick::Cookie.parse_set_cookies( @response_headers['Set-Cookie'].to_s )
                cookies << WEBrick::Cookie.parse_set_cookies( @response_headers['set-cookie'].to_s )
            rescue
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

                cookies_arr[i][key] = val
            }

            # cookies.reject!{ |cookie| cookie['name'] == cookies_arr[i]['name'] }

            cookies_arr[i] = Element::Cookie.new( @url, cookies_arr[i] )
        }
        cookies_arr.flatten!
        return cookies_arr
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
            if URI.parse( link ).host
                return link
            end
        rescue Exception => e
            return nil if link.nil?
            #      return link
        end

        # remove anchor
        link = URI.encode( link.to_s.gsub( /#[a-zA-Z0-9_-]*$/, '' ) )

        begin
            relative = URI(link)
            url = URI.parse( @url )

            absolute = url.merge(relative)

            absolute.path = '/' if absolute.path.empty?
        rescue Exception => e
            return
        end

        return absolute.to_s
    end

    #
    # Returns +true+ if *uri* is in the same domain as the page, returns
    # +false+ otherwise
    #
    def in_domain?( uri )
        curi = URI.parse( URI.escape( uri.to_s ) )

        if( @opts.follow_subdomains )
            return extract_domain( curi ) ==  extract_domain( URI( @url.to_s ) )
        end

        return curi.host == URI.parse( URI.escape( @url.to_s ) ).host
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
            return true if url.to_s =~ pattern
        }
        return false
    end


    private

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
            select['attrs']['value'] = select['options'][0]['value']
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
