=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Framework
module Parts

module Data

    # @return   [Data::Framework]
    def data
        Arachni::Data.framework
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
        Page.from_url( url_queue.pop, http: { update_cookies: true } ) do |page|
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
                print_error "Couldn't get a response after #{AUDIT_PAGE_MAX_TRIES} tries."
            else
                print_bad "Retrying for: #{page.url}"
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
