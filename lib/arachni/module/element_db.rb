=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

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
    @@forms    ||= Set.new

    #
    # page links
    #
    @@links    ||= Set.new

    #
    # page cookies
    #
    @@cookies  ||= Set.new

    #
    # Initializes @@forms with the cookies found during the crawl/analysis
    #
    def init_forms( forms )
      @@forms |= forms.map { |form| form.id }
    end

    #
    # Initializes @@links with the links found during the crawl/analysis
    #
    def init_links( links )
      @@links |= links.map { |link| link.id }
    end

    #
    # Initializes @@cookies with the cookies found during the crawl/analysis
    #
    def init_cookies( cookies )
      @@cookies = cookies
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
        new_forms ||= []

        forms.each {
            |form|

            next if form.action.include?( seed )
            next if form.auditable.size == 0

            if !@@forms.include?( form.id )
                @@forms << form.id
                new_forms << form
                form_cnt += 1
            end
        }

        return new_forms, form_cnt
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
      new_links ||= []
      links.each {
          |link|

          next if !link
          next if link.action.include?( seed )

          if !@@links.include?( link.id )
              @@links    << link.id
              new_links << link
              link_cnt += 1
          end
      }

      return new_links, link_cnt
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
                elsif !cookie_in_jar?( cookie )
                    @new_cookies << cookie
                    cookie_cnt += 1
                end
            }
        }

        @@cookies.flatten!
        @@cookies |= @new_cookies

        return [ @@cookies, cookie_cnt ]
    end

    def cookie_in_jar?( cookie )
        @@cookies.each {
            |c|
            return true if c.raw['name'] == cookie.raw['name']
        }
        return false
    end

end

end
end
