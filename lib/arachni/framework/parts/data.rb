=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Framework
module Parts

# Provides access to {Arachni::Data::Framework} and helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Data

    # @return   [Data::Framework]
    def data
        Arachni::Data.framework
    end

    # @param    [Page]  page
    #   Page to push to the page audit queue -- increases {#page_queue_total_size}
    #
    # @return   [Bool]
    #   `true` if push was successful, `false` if the `page` matched any
    #   exclusion criteria or has already been seen.
    def push_to_page_queue( page, force = false )
        return false if !force && (!accepts_more_pages? || state.page_seen?( page ) ||
            page.scope.out? || page.scope.redundant?( true ))

        # We want to update from the already loaded page cache (if there is one)
        # as we have to store the page anyways (needs to go through Browser analysis)
        # and it's not worth the resources to parse its elements.
        #
        # We're basically doing this to give the Browser and Trainer a better
        # view of what elements have been seen, so that they won't feed us pages
        # with elements that they think are new, but have been provided to us by
        # some other component; however, it wouldn't be the end of the world if
        # that were to happen.
        ElementFilter.update_from_page_cache page

        data.push_to_page_queue page
        state.page_seen page

        true
    end

    # @param    [String]  url
    #   URL to push to the audit queue -- increases {#url_queue_total_size}
    #
    # @return   [Bool]
    #   `true` if push was successful, `false` if the `url` matched any
    #   exclusion criteria or has already been seen.
    def push_to_url_queue( url, force = false )
        return if !force && !accepts_more_pages?

        url = to_absolute( url ) || url
        if state.url_seen?( url ) || skip_path?( url ) || redundant_path?( url, true )
            return false
        end

        data.push_to_url_queue url
        state.url_seen url

        true
    end

    # @return   [Integer]
    #   Total number of pages added to the {#push_to_page_queue page audit queue}.
    def page_queue_total_size
        data.page_queue_total_size
    end

    # @return   [Integer]
    #   Total number of URLs added to the {#push_to_url_queue URL audit queue}.
    def url_queue_total_size
        data.url_queue_total_size
    end

    # @return   [Hash<String, Integer>]
    #   List of crawled URLs with their HTTP codes.
    def sitemap
        data.sitemap
    end

    private

    def page_queue
        data.page_queue
    end

    def url_queue
        data.url_queue
    end

    def has_audit_workload?
        !url_queue.empty? || !page_queue.empty?
    end

    def pop_page_from_url_queue( &block )
        return if url_queue.empty?

        grabbed_page = nil
        Page.from_url( url_queue.pop,
                       http: { update_cookies: true, performer: self }
        ) do |page|
            @retries[page.url.hash] ||= 0

            if (location = page.response.headers.location)
                [location].flatten.each do |l|
                    print_info "Scheduled #{page.code} redirection: #{page.url} => #{l}"
                    push_to_url_queue to_absolute( l, page.url )
                end
            end

            if page.code != 0
                grabbed_page = page
                block.call grabbed_page if block_given?
                next
            end

            if @retries[page.url.hash] >= AUDIT_PAGE_MAX_TRIES
                @failures << page.url

                print_error "Giving up trying to audit: #{page.url}"
                print_error "Couldn't get a response after #{AUDIT_PAGE_MAX_TRIES} tries: #{page.response.return_message}."
            else
                print_bad "Retrying for: #{page.url} [#{page.response.return_message}]"
                @retries[page.url.hash] += 1
                url_queue << page.url
            end

            grabbed_page = nil
            block.call grabbed_page if block_given?
        end
        http.run if !block_given?
        grabbed_page
    end

    # @return   [Page]
    def pop_page_from_queue
        return if page_queue.empty?
        page_queue.pop
    end

    def add_to_sitemap( page )
        data.add_page_to_sitemap( page )
    end

    def push_paths_from_page( page )
        page.paths.select { |path| push_to_url_queue( path ) }
    end

end

end
end
end
