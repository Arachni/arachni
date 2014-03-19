=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

# Filter for {Element elements}, used to keep track of what elements have been
# seen and separate them from new ones.
#
# Mostly used by the {Trainer}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module ElementFilter
    include Utilities

    @@mutex    ||= Mutex.new
    @@forms    ||= Support::LookUp::HashSet.new
    @@links    ||= Support::LookUp::HashSet.new
    @@cookies  ||= Set.new

    def self.reset
        @@forms.clear
        @@links.clear
        @@cookies.clear
    end

    def self.synchronize( &block )
        @@mutex.synchronize( &block )
    end

    def synchronize( &block )
        @@mutex.synchronize( &block )
    end

    def init_db_from_page( page )
        init_links page.links
        init_forms page.forms
        init_cookies page.cookies
    end

    # Initializes @@forms with the cookies found during the crawl/analysis
    def init_forms( forms )
        forms.each { |form| @@forms << form.id }
    end

    # Initializes @@links with the links found during the crawl/analysis
    def init_links( links )
        links.each { |link| @@links << link.id }
    end

    # Initializes @@cookies with the cookies found during the crawl/analysis
    def init_cookies( cookies )
        @@cookies = cookies.map { |c| d = c.dup; d.page = nil; d }
    end

    # Updates @@forms wth new forms that may have dynamically appeared<br/>
    # after analyzing the HTTP responses during the audit.
    #
    # @param    [Array<Element::Form>] forms
    def update_forms( forms )
        return 0 if forms.size == 0

        synchronize do
            new_form_cnt = 0
            forms.each do |form|
                next if @@forms.include?( form.id )
                @@forms << form.id
                new_form_cnt += 1
            end
            new_form_cnt
        end
    end

    # Updates @@links wth new links that may have dynamically appeared<br/>
    # after analyzing the HTTP responses during the audit.
    #
    # @param    [Array<Element::Link>]    links
    def update_links( links )
      return 0 if links.size == 0

      synchronize do
          new_link_cnt = 0
          links.each do |link|
              next if @@links.include?( link.id )
              @@links << link.id
              new_link_cnt += 1
          end

          new_link_cnt
      end
    end

    # Updates @@cookies wth new cookies that may have dynamically appeared
    # after analyzing the HTTP responses during the audit.
    #
    # @param    [Array<Element::Cookie>]   cookies
    def update_cookies( cookies )
        return 0 if cookies.size == 0

        synchronize do
            new_cookie_cnt = 0
            cookies.reverse.each do |cookie|
                @@cookies.each_with_index do |page_cookie, i|
                    if page_cookie.name == cookie.name
                        @@cookies[i] = cookie
                    elsif !cookie_in_jar?( cookie )
                        new_cookie_cnt += 1
                    end
                end
            end

            new_cookie_cnt
        end
    end

    def cookie_in_jar?( cookie )
        @@cookies.each { |c| return true if c.name == cookie.name }
        false
    end

    extend self
end

end
