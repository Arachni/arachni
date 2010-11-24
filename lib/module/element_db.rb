=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end
module Arachni
module Module

#
# Holds a database of all auditable elements of the current page,<br/>
# including elements that have appeared dynamically during the audit.
#
# The database is updated by the {Trainer}.
#
# For each page that is audited the database is reset.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2.1
#
module ElementDB

    include Arachni::Module::Utilities

    #
    # page forms
    #
    @@forms    ||= []

    #
    # page links
    #
    @@links    ||= []

    #
    # page cookies
    #
    @@cookies  ||= []

    #
    # Initializes @@forms with the cookies found during the crawl/analysis
    #
    def init_forms( forms )
      @@forms = forms
    end

    #
    # Initializes @@links with the links found during the crawl/analysis
    #
    def init_links( links )
      @@links = links
    end

    #
    # Initializes @@cookies with the cookies found during the crawl/analysis
    #
    def init_cookies( cookies )
      @@cookies = cookies

      cookie_jar = @http.parse_cookie_str( @http.init_headers['cookie'] )
      cookie_jar = get_cookies_simple( @@cookies ).merge( cookie_jar )
      @http.set_cookies( cookie_jar )

    end

    #
    # Updates @@forms wth new forms that may have dynamically appeared<br/>
    # after analyzing the HTTP responses during the audit.
    #
    # @param    [Array<Element::Form>] forms
    #
    def update_forms( forms )

        return [], 0 if forms.size == 0

        form_cnt = 0
        @new_forms ||= []

        forms.each {
            |form|

            next if form.action.include?( seed )
            next if form.auditable.size == 0

            if !(index = forms_include?( form ) )
                @@forms << form
                @new_forms << form
                form_cnt += 1
            end
        }

        return @new_forms, form_cnt

    end

    #
    # Updates @@links wth new links that may have dynamically appeared<br/>
    # after analyzing the HTTP responses during the audit.
    #
    # @param    [Array<Element::Link>]    links
    #
    def update_links( links )
      return [], 0 if links.size == 0

      link_cnt = 0
      @new_links ||= []
      links.each {
          |link|

          next if !link
          next if link.action.include?( seed )

          if !(index = links_include?( link ) )
              @@links    << link
              @new_links << link
              link_cnt += 1
          end
      }

      return @new_links, link_cnt
    end

    #
    # Updates @@cookies wth new cookies that may have dynamically appeared<br/>
    # after analyzing the HTTP responses during the audit.
    #
    # @param    [Array<Element::Cookie>]   cookies
    #
    def update_cookies( cookies )
        return [], 0 if cookies.size == 0

        cookie_cnt = 0
        @new_cookies ||= []

        cookies.each_with_index {
            |cookie|

            @@cookies.each_with_index {
                |page_cookie, i|

                if( page_cookie.raw['name'] == cookie.raw['name'] )
                    @@cookies[i] = cookie
                else
                    @new_cookies << cookie
                    cookie_cnt += 1
                end
            }
        }

        @@cookies.flatten!

        @@cookies |= @new_cookies

        cookie_jar = @http.parse_cookie_str( @http.init_headers['cookie'] )
        cookie_jar = get_cookies_simple( @@cookies ).merge( cookie_jar )

        @http.set_cookies( cookie_jar )
        return [ @@cookies, cookie_cnt ]
    end

    private

    def forms_include?( form )
        @@forms.each_with_index {
            |page_form, i|
            return i if( form.id == page_form.id )

        }
        return false
    end

    def links_include?( link )
        @@links.each_with_index {
            |page_link, i|
            return i if( link.id == page_link.id )

        }
        return false
    end


    #
    # Returns cookies as a name=>value hash
    #
    # @return    [Hash]    the cookie attributes, values, etc
    #
    def get_cookies_simple( incookies = nil )
        cookies = Hash.new( )

        incookies = get_cookies( ) if !incookies

        incookies.each {
            |cookie|
            cookies[cookie.raw['name']] = cookie.raw['value']
        }

        return cookies if !@page.cookiejar
        @page.cookiejar.merge( cookies )
    end


end

end
end
