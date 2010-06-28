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
# Arachni::HTTP class<br/>
# Provides a simple HTTP interface for modules
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: 0.1-planning
#
class HTTP
  
  attr_reader :http
  attr_reader :url
  
  #
  # Initializes the HTTP session given a start URL respecting
  # system wide settings for HTTP basic auth and proxy
  #
  # @param [String] url start URL
  #
  # @return [Net::HTTP]
  #
  def initialize( url )
    @url = parse_url( url)
    
    @session = Net::HTTP.new( @url.host, @url.port,
        $runtime_args[:proxy_addr], $runtime_args[:proxy_port],
        $runtime_args[:proxy_user], $runtime_args[:proxy_pass] )
    
    if @url.scheme == 'https'
      @session.use_ssl = true
      @session.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    
    @session = @session.start
  end
  
  #
  # Gets a URL passing the provided variables
  #
  # @param [URI]  url  URL to get
  # @param  [Array<Hash<String, String>>] url_vars array of name=>value pairs
  #
  # @return [HTTP::Response]
  #
  def get( url, url_vars )
   @session.get( @url.path +  a_to_s( url_vars ) )
  end
  
  def post
  end
  
  def cookie
  end
  
  #
  # Encodes and parses a URL String 
  #
  # @param [String] url URL String
  #
  # @return [URI] URI object
  #
  def parse_url( url )
    URI.parse( URI.encode( url ) )
  end
  
  private
  
  #
  # Converts an Array of Hash<String, String> objects
  # to a path URL String with variables
  #
  # @return [String]
  #
  def a_to_s( arr )
    if arr.length == 0 then return '' end
    
    str = '?'
    arr.each {
      |pair|
      str += pair[0] +  '=' + pair[1] + '&' 
    }
    str
  end
  
  
end
end