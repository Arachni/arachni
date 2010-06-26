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
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: 0.1-planning
#
class Spider

  # 
  # Structure of the site in Hash structure
  # @return [Hash<String, Hash<Array, Hash>>]
  #
  attr_reader :site_structure
  
  #
  # URL to crawl
  # @return [URL]
  #
  attr_reader :url
  
  #
  # Array of extracted HTML forms
  # @return [Array<Hash <String, String> >]
  #
  attr_reader :forms
  
  #
  # Array of extracted HTML links
  # @return [Array<Hash <String, String> >]
  #
  attr_reader :links
  
  #
  # Array of extracted cookies
  # @return [Array<Hash <String, String> >]
  #
  attr_reader :cookies

  #
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
  #
  # @return [Hash]
  #
  attr_reader :opts
  
  
  #
  # Constructor <br/>
  # Instantiates Spider with user options.
  # 
  # @param  [{String => Symbol}] user_opts  hash with option => value pairs
  # @return [Hash<String, Hash<Array, Hash>>] site_tree
  #
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
          @site_structure[url]['forms'] = get_forms( page )
        end

        if @opts[:audit_links]
          @site_structure[url]['links'] = get_links( page )
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


  #  
  # Checks if URL is valid.
  #
  # @param  [URL]   URL
  #
  # @return [true, false]
  #
  def valid_url?( url )
    return true
  end

  #
  # Extracts forms from HTML document
  #
  # @param [Anemone::Page] page Anemone page
  #
  # @return [Array<Hash <String, String> >] array of forms
  #
  def get_forms( page )
    
    elements = []
      
    forms = page.body.scan( /<form(.*?)<\/form>/ixm )
    
    forms.each_with_index {
      |form, i|
      form = form[0]
      
      elements[i] = Hash.new
      
      elements[i] = get_form_inputs( form )
      elements[i]['attrs'] = get_form_attrs( form )
#      puts '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    }
    
    elements
  end

  #
  # Extracts links from HTML document
  #
  # @param [Anemone::Page] page Anemone page
  #
  # @return [Array<Hash <String, String> >] of links
  #
  def get_links( page )
    get_elements_by_name( 'a', page )
  end
    
  #
  # Extracts cookies from Anemone page
  #
  # @param  [Anemone::Page] page Anemone page
  #
  # @return [Array<Hash <String, String> >] of cookies
  #
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
  
  
  
  private
  
  #
  # Parses the attributes inside the <form ....> tag
  # 
  # @param  [String] form   HTML code for the form tag
  # 
  # @return [Array<Hash<String, String>>]
  # 
  def get_form_attrs( form )
    form_attr_html = form.scan( /(.*?)>/ixm )
    get_attrs_from_tag( 'form', '<form ' + form_attr_html[0][0] + '>' )[0]
  end

  #
  # Parses the attributes of input fields
  # @param  [String] html   HTML code for the form tag
  # 
  # @return [Hash<Hash<String, String>>]
  # 
  def get_form_inputs( html )
    inputs = html.scan( /<input(.*?)>/ixm )
#    ap inputs
    
    elements = Hash.new
    inputs.each_with_index {
      |input, i|
      elements[i] =
        get_attrs_from_tag( 'input', '<input ' + input[0] + '/>' )[0]
    }
    
    elements
#    puts '-------------'
  end


  #
  # Gets attributes from HTML code of a tag
  #
  # @param  [String] tag    tag name (a, form, input)  
  # @param  [String] html   HTML code for the form tag
  # 
  # @return [Array<Hash<String, String>>]
  # 
  def get_attrs_from_tag( tag, html )
    doc = Nokogiri::HTML( html )
    
    elements = []
    doc.search( tag ).each_with_index {
      |element, i|
      
      elements[i] = Hash.new
       
        element.each {
         |attribute|
#         ap attribute
         
         elements[i][attribute[0].downcase] = attribute[1]
       }
       
#      pp element.attributes
    }
#    puts '------------------'

    elements
  end
  
  
  # Extracts elements by name from HTML document
  #
  # @param [String] name 'form', 'a', 'div', etc.
  # @param [Anemone::Page] page Anemone page
  #
  # @return [Array<Hash <String, String> >] of elements
  #
  def get_elements_by_name( name, page )
    elements = []
    page.doc.search( name ).each_with_index do |input, i|
  
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

end
