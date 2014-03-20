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
class ElementFilter
class <<self

    def reset
        @mutex   = Mutex.new
        @forms   = Support::LookUp::HashSet.new
        @links   = Support::LookUp::HashSet.new
        @cookies = Support::LookUp::HashSet.new
        nil
    end

    # @return    [Support::LookUp::HashSet]
    def forms
        @forms
    end

    # @return    [Support::LookUp::HashSet]
    def links
        @links
    end

    # @return    [Support::LookUp::HashSet]
    def cookies
        @cookies
    end

    # @param    [Element::Form] form
    # @return   [Bool]
    def forms_include?( form )
        forms.include? form.id
    end

    # @param    [Element::Link] link
    # @return   [Bool]
    def links_include?( link )
        links.include? link.id
    end

    # @param    [Element::Cookie] cookie
    # @return   [Bool]
    def cookies_include?( cookie )
        cookies.include? cookie.id
    end

    # @param    [Element::Base] element
    # @return   [Bool]
    def include?( element )
        forms_include?( element ) || links_include?( element ) ||
            cookies_include?( element )
    end

    # @param    [Page]  page
    # @return   [Integer]   Amount of new elements.
    def update_from_page( page )
        update_links( page.links ) + update_forms( page.forms ) +
            update_cookies( page.cookies )
    end

    # Updates the elements from the {Page#cache}, useful in situations where
    # resources need to be preserved (thus avoiding a full page parse) and the
    # need for a full coverage update isn't vital.
    #
    # @param    [Page]  page
    # @return   [Integer]   Amount of new elements.
    def update_from_page_cache( page )
        update_links( page.cache[:links] ) + update_forms( page.cache[:forms] ) +
            update_cookies( page.cache[:cookies] )
    end

    # @param    [Array<Element::Form>] forms
    # @return   [Integer]   Amount of new forms.
    def update_forms( forms )
        forms = [forms].flatten.compact
        return 0 if forms.size == 0

        synchronize do
            new_form_cnt = 0
            forms.each do |form|
                next if @forms.include?( form.id )
                @forms << form.id
                new_form_cnt += 1
            end
            new_form_cnt
        end
    end

    # @param    [Array<Element::Link>]    links
    # @return   [Integer]   Amount of new links.
    def update_links( links )
        links = [links].flatten.compact
        return 0 if links.size == 0

        synchronize do
            new_link_cnt = 0
            links.each do |link|
                next if @links.include?( link.id )
                @links << link.id
                new_link_cnt += 1
            end
            new_link_cnt
        end
    end

    # @param    [Array<Element::Cookie>]   cookies
    # @return   [Integer]   Amount of new cookies.
    def update_cookies( cookies )
        cookies = [cookies].flatten.compact
        return 0 if cookies.size == 0

        synchronize do
            new_cookie_cnt = 0
            cookies.each do |cookie|
                next if @cookies.include? cookie.id
                @cookies << cookie.id
                new_cookie_cnt += 1
            end
            new_cookie_cnt
        end
    end

    private

    def synchronize( &block )
        @mutex.synchronize( &block )
    end

end

reset
end

end
