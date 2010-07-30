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

    attr_accessor :url
    attr_accessor :query_vars
    
    attr_accessor :html
    
    attr_accessor :headers
    
    attr_accessor :elements
    
    attr_accessor :cookiejar
    
        
    def initialize( opts = {} )
        opts.each {
            |k, v|
            send( "#{k}=", v )
        }

    end
    
    def get_forms
        elements['forms']
    end
    
    def get_links
        elements['links']
    end
    
    def get_cookies
        elements['cookies']
    end

end

end
