=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

class Parser
#
# Arachni::Page class
#
# It holds page data like elements, cookies, headers, etc...
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
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
    # @see Parser#links
    #
    # @return    [Array]
    #
    attr_accessor :links

    #
    # @see Parser#forms
    #
    # @return    [Array]
    #
    attr_accessor :forms

    #
    # @see Parser#cookies
    #
    # @return    [Array]
    #
    attr_accessor :cookies

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
    # Returns an array of forms from {#forms} with its attributes and<br/>
    # its auditable inputs as a name=>value hash
    #
    # @return    [Array]
    #
    def forms_simple( )
        forms = []
        @forms.each {
            |form|
            forms << form.simple
        }
        return forms
    end

    #
    # Returns links from {#links} as a name=>value hash with href as key
    #
    # @return    [Hash]
    #
    def links_simple
        links = []
        @links.each {
            |link|
            links << link.simple
        }
        return links
    end

    #
    # Returns cookies from {#cookies} as a name=>value hash
    #
    # @return    [Hash]    the cookie attributes, values, etc
    #
    def cookies_simple
        cookies = { }

        @cookies.each {
            |cookie|
            cookies.merge!( cookie.simple )
        }
        return cookies
    end

end
end
end
