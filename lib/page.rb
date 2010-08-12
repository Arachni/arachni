=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

#
# Arachni::Page class
#    
# It holds page data like elements, cookies, headers, etc...
#    
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1-pre
#
class Page

    #
    # @return    [String]    url of the page
    #
    attr_accessor :url
    
    #
    # @return    [Hash]    url variables
    #
    attr_accessor :query_vars
    
    #
    # @return    [String]    the HTML response
    #
    attr_accessor :html
    
    #
    # @return    [Hash]    response headers
    #
    attr_accessor :headers
    
    #
    # @see Analyzer#get_headers
    #
    # @return    [Hash]    auditable HTTP request headers
    #
    attr_accessor :request_headers
    
    #
    # @see Analyzer#run
    # @see Analyzer#get_links
    # @see Analyzer#get_forms
    # @see Analyzer#get_cookies
    #
    # @return    [Hash]    auditable HTML elements (links/forms/cookies)
    #
    attr_accessor :elements
    
    #
    # Cookies extracted from the supplied cookiejar
    #
    # @return    [Hash]
    #
    attr_accessor :cookiejar
    
    def initialize( opts = {} )
        opts.each {
            |k, v|
            send( "#{k}=", v )
        }

    end
    
    #
    # Returns the form elements in {Page#elements}
    #
    def get_forms
        elements['forms']
    end
    
    #
    # Returns the links elements in {Page#elements}
    #
    def get_links
        elements['links']
    end
    
    #
    # Returns the cookies elements in {Page#elements}
    #
    def get_cookies
        elements['cookies'].reject {
            |cookie|
            Options.instance.exclude_cookies.include?( cookie['name'] )
        }
    end

end

end
