=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

module Arachni
#
# Analyzer class<br/>
# Analyzes HTML code extracting forms, links and cookies
# depending on user opts.
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: 0.1-planning
#
class Analyzer

  #
  # Structure of the html elements in Hash format
  # @return [Hash<String, Hash<Array, Hash>>]
  #
  attr_reader :structure

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
  # Hash of options passed to initialize( opts ).
  #
  attr_reader :opts
  
  #
  # Constructor <br/>
  # Instantiates Analyzer class with user options.
  #
  # @param  [{String => Symbol}] opts  hash with option => value pairs
  #
  def initialize( opts )
    @url = ''
    @opts = opts
    @structure = Hash.new
  end

  #
  # Runs the Analyzer and extracts forms, links and cookies
  #
  # @param [String] url the url of the HTML code, mainly used for debugging
  # @param [String] html HTML code  to be analyzed
  # @param [Hash] headers HTTP headers
  #
  # @return [Hash<String, Hash<Array, Hash>>] HTML elements
  #
  def run( url, html, headers )

    @url = url

    print "[" if @opts[:arachni_verbose]

    elem_count = 0
    if @opts[:audit_forms]
      @structure['forms'] = @forms = get_forms( html )
      elem_count += form_count = @structure['forms'].length
      print "Forms: #{form_count}\t" if @opts[:arachni_verbose]
    end

    if @opts[:audit_links]
      @structure['links'] = @links = get_links( html )
      elem_count += link_count = @structure['links'].length
      print "Links: #{link_count}\t" if @opts[:arachni_verbose]
    end

    if @opts[:audit_cookies]
      @structure['cookies'] = @cookies = get_cookies( headers['set-cookie'].to_s )
      elem_count += cookie_count =  @structure['cookies'].length
      print "Cookies: #{cookie_count}" if @opts[:arachni_verbose]
    end

    print "]\n\n" if @opts[:arachni_verbose]

    return @structure
  end

  #
  # Extracts forms from HTML document
  #
  # @param  [String] html
  #
  # @return [Array<Hash <String, String> >] array of forms
  #
  def get_forms( html )

    elements = []

    begin
      forms = html.scan( /<form(.*?)<\/form>/ixm )
    rescue Exception => e
      puts "Error: Couldn't get forms from '" + @url + "' [" + e.to_s + "]"
      print "[" if @opts[:arachni_verbose]
      return {}
    end

    forms.each_with_index {
      |form, i|
      form = form[0]

      elements[i] = Hash.new

      elements[i] = get_form_inputs( form )
      elements[i]['attrs'] = get_form_attrs( form )
    }

    elements
  end

  #
  # Extracts links from HTML document
  #
  # @param  [String] html
  #
  # @return [Array<Hash <String, String> >] of links
  #
  def get_links( html )
    links = []
    get_elements_by_name( 'a', html ).each_with_index {
      |link, i|
      links[i] = link
      links[i]['vars'] = get_link_vars( link['href'] )
    }
  end

  #
  # Extracts cookies from an HTTP headers
  #
  # @param  [String] headers HTTP headers
  #
  # @return [Array<Hash <String, String> >] of cookies
  #
  def get_cookies( headers )
    cookies = WEBrick::Cookie.parse_set_cookies( headers )

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

  
  def get_link_vars( link )
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
  # @param  [String] html
  #
  # @return [Array<Hash <String, String> >] of elements
  #
  def get_elements_by_name( name, html )

    doc = Nokogiri::HTML( html )

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

end
end