=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

require Options.paths.lib + 'element_filter'

# Trainer class
#
# Analyzes key HTTP responses looking for new auditable elements.
#
# @author Tasos Laskos <tasos.laskos@arachni-scanner.com>
class Trainer
    include UI::Output
    include Utilities
    include Support::Mixins::Observable

    # @!method on_new_page( &block )
    advertise :on_new_page

    personalize_output

    MAX_TRAININGS_PER_URL = 25

    # @param    [Arachni::Framework]  framework
    def initialize( framework )
        super()

        @framework  = framework
        @updated    = false

        @trainings_per_url = Hash.new( 0 )

        # get us setup using the page that is being audited as a seed page
        framework.on_page_audit { |page| self.page = page }

        framework.http.on_complete do |response|
            next if !response.request.train?

            if response.redirect?
                reference_url = @page ? @page.url : @framework.options.url
                redirect_url  = to_absolute( response.headers.location, reference_url )

                framework.http.get( redirect_url ) { |res| push res }
                next
            end

            push response
        end
    end

    # Passes the response on for analysis.
    #
    # If the response contains new elements it creates a new page
    # with those elements and pushes it a buffer.
    #
    # These new pages can then be retrieved by flushing the buffer (#flush).
    #
    # @param  [Arachni::HTTP::Response]  response
    def push( response )
        if !@page
            print_debug 'No seed page assigned yet.'
            return
        end

        if !@framework.accepts_more_pages?
            print_info 'No more pages accepted, skipping analysis.'
            return
        end

        return false if !response.text?

        skip_message = nil
        if @trainings_per_url[response.url] >= MAX_TRAININGS_PER_URL
            skip_message = "Reached maximum trainings (#{MAX_TRAININGS_PER_URL})"
        elsif response.scope.redundant?
            skip_message = 'Matched redundancy filters'
        elsif response.scope.out?
            skip_message = 'Matched exclusion criteria'
        end

        if skip_message
            print_verbose "#{skip_message}, skipping: #{response.url}"
            return false
        end

        analyze response
        true
    rescue => e
        print_exception e
        nil
    end

    # Sets the current working page and {ElementFilter.update_from_page updates}
    # the {ElementFilter}.
    #
    # @param    [Arachni::Page]    page
    def page=( page )
        ElementFilter.update_from_page page
        @page = page.dup
    end

    private

    # Analyzes a response looking for new links, forms and cookies.
    #
    # @param   [Arachni::HTTP::Response]  response
    def analyze( response )
        print_debug "Started for response with request ID: ##{response.request.id}"

        incoming_page    = response.to_page
        has_new_elements = has_new?( incoming_page, :cookies )

        # if the response body is the same as the page body and
        # no new cookies have appeared there's no reason to analyze the page
        if incoming_page.body == @page.body && !has_new_elements &&
            @page.url == incoming_page.url
            print_debug 'Page hasn\'t changed.'
            return
        end

        [ :forms, :links ].each { |type| has_new_elements ||= has_new?( incoming_page, type ) }

        if has_new_elements
            @trainings_per_url[incoming_page.url] += 1

            notify_on_new_page incoming_page
            @framework.push_to_page_queue( incoming_page )

        # If the page is pushed, paths will be extracted eventually, if not, we
        # need to do it now.
        else
            incoming_page.paths.each do |path|
                @framework.push_to_url_queue( path )
            end
        end

        print_debug 'Training complete.'
    end

    def has_new?( incoming_page, element_type )
        count = ElementFilter.send( "update_#{element_type}".to_sym, incoming_page.send( element_type ) )
        incoming_page.clear_cache
        return if count == 0

        print_info "Found #{count} new #{element_type}."
        true
    end

end
end
