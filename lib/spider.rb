=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end
require 'rubygems'
require 'anemone'
require 'nokogiri'
require 'lib/anemone/http'
require 'lib/net/http'
require 'ap'
require 'pp'


#
# Spider class<br/>
# Crawls the specified URL in opts[:url] and analyzes the HTML code
# extracting forms, links and cookies depending on user opts.
#
# @author: Zapotek <zapotek@segfault.gr>
# @version: 0.1-planning
#
class Spider

  #
  # Structure of the site in hash format:
  #
  # "url" => {
  #   "links" => [],
  #   "forms" => [],
  #   "cookies" => []
  # }
  #
  attr_reader :site_structure
  # URL to crawl
  attr_reader :url
  # Array of extracted HTML forms
  attr_reader :forms
  # Array of extracted HTML links
  attr_reader :links
  # Array of extracted cookies
  attr_reader :cookies

  # Hash of options passed to initialize( user_opts ).
  #
  # Default:
  #  opts = {
  #        :threads              =>  3,
  #        :discard_page_bodies  =>  false,
  #        :user_agent           =>  "Arachni/0.1",
  #        :delay                =>  0,
  #        :obey_robots_txt      =>  false,
  #        :depth_limit          =>  false,
  #        :link_depth_limit     =>  false,
  #        :redirect_limit       =>  5,
  #        :storage              =>  nil,
  #        :cookies              =>  nil,
  #        :accept_cookies       =>  true
  #  }
  attr_reader :opts
  #
  # Constructor <br/>
  # Instantiates Spider with user options.<br/>
  # <br/>
  # @param  user_opts  hash with option => value pairs
  #
  # @return site_tree
  def initialize( user_opts )

    @opts = {
      :threads              =>  3,
      :discard_page_bodies  =>  false,
      :user_agent           =>  "Arachni/0.1",
      :delay                =>  0,
      :obey_robots_txt      =>  false,
      :depth_limit          =>  false,
      :link_depth_limit     =>  false,
      :redirect_limit       =>  5,
      :storage              =>  nil,
      :cookies              =>  nil,
      :accept_cookies       =>  true,
      :proxy_addr           =>  nil,
      :proxy_port           =>  nil,
      :proxy_user           =>  nil,
      :proxy_pass           =>  nil
    }.merge user_opts

    if valid_url?( @opts[:url] )
      @url = @opts[:url]
    else
      return
    end

    i = 1
    @site_structure = Hash.new
    @opts[:include] =@opts[:include] ? @opts[:include] : Regexp.new( '.*' )
    $opts = @opts
    Anemone.crawl( url, opts ) do |anemone|
      anemone.on_pages_like( @opts[:include] ) do |page|

        url = page.url.to_s

        if url =~ @opts[:exclude]
          
          if @opts[:arachni_verbose]
            puts '[Skipping: Matched exclude rule] ' + url
          end
          
          next
        end
        
        puts "[OK] " + url if @opts[:arachni_verbose]
        #        ap @opts

        @site_structure[url] = Hash.new

        if @opts[:audit_forms]
          @site_structure[url]['forms'] = get_forms( page.doc )
        end

        if @opts[:audit_links]
          @site_structure[url]['links'] = get_links( page.doc )
        end

        if @opts[:audit_cookies]
          @site_structure[url]['cookies'] = get_cookies( page )
        end

        page.discard_doc!()

        if( @opts[:link_depth_limit] != false &&
        @opts[:link_depth_limit] <= i )
          return
        end

        i+=1

      end
    end

    return @site_structure
  end

  # Checks if URL is valid.
  #
  # @param  url   URL String
  #
  # @return bool
  def valid_url?( url )
    return true
  end

  # Extracts forms from HTML document
  #
  # @param  doc   Nokogiri doc
  #
  # @return Array of forms
  def get_forms( doc )
    get_elements_by_name( 'form', doc )
  end

  # Extracts links from HTML document
  #
  # @param  doc   Nokogiri doc
  #
  # @return Array of links
  def get_links( doc )
    get_elements_by_name( 'a', doc )
  end

  # Extracts elements by name from HTML document
  #
  # @param  name  name String ('form', 'a', 'div', etc.)
  #
  # @param  doc   Nokogiri doc
  #
  # @return Array of elements
  def get_elements_by_name( name, doc )
    elements = []
    doc.search( name ).each_with_index do |input, i|

    elements[i] = Hash.new
    input.each {
    |attribute|
    elements[i][attribute[0]] = attribute[1]
    }

    input.children.each {
    |child|
    child.each{ |attribute| elements[i][attribute[0]] = attribute[1] }
    }

    end rescue []

    return elements
  end

  # Extracts cookies from Anemone page
  #
  # @param  page  Anemone page
  #
  # @return Array of cookies
  def get_cookies( page )
    cookies_str = page.headers['set-cookie'].to_s
    cookies = WEBrick::Cookie.parse_set_cookies( cookies_str )

    cookies_arr = []

    cookies.each_with_index {
      |cookie, i|
      cookies_arr[i] = Hash.new

      cookie.instance_variables.each {
        |var|
        value = cookie.instance_variable_get( var ).to_s
        value.strip!
        cookies_arr[i][var.to_s.gsub( /@/, '' )] =
        value.gsub( /[\"\\\[\]]/, '' )
      }
    }

    return cookies_arr
  end

end
