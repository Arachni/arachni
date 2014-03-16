=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

require Options.paths.lib + 'element_filter'

# Trainer class
#
# Analyzes key HTTP responses looking for new auditable elements.
#
# @author Tasos Laskos <tasos.laskos@gmail.com>
class Trainer
    include UI::Output
    include ElementFilter
    include Utilities

    personalize_output

    MAX_TRAININGS_PER_URL = 25

    # @param    [Arachni::Framework]  framework
    def initialize( framework )
        @framework  = framework
        @updated    = false

        @on_new_page_blocks = []
        @trainings_per_url  = Hash.new( 0 )

        # get us setup using the page that is being audited as a seed page
        framework.on_audit_page { |page| self.page = page }

        framework.http.add_on_complete do |response|
            next if !response.request.train?

            if response.redirect?
                reference_url = @page ? @page.url : @framework.opts.url
                redirect_url  = to_absolute( response.headers.location, reference_url )

                framework.http.get( redirect_url ) { |res| push res }
                next
            end

            push response
        end
    end

    #
    # Passes the response on for analysis.
    #
    # If the response contains new elements it creates a new page
    # with those elements and pushes it a buffer.
    #
    # These new pages can then be retrieved by flushing the buffer (#flush).
    #
    # @param  [Arachni::HTTP::Response]  response
    #
    def push( response )
        if !@page
            print_debug 'No seed page assigned yet.'
            return
        end

        if @framework.page_limit_reached?
            print_info 'Link count limit reached, skipping analysis.'
            return
        end

        @parser = Parser.new( response )

        return false if !@parser.text?

        skip_message = nil
        if @trainings_per_url[@parser.url] >= MAX_TRAININGS_PER_URL
            skip_message = "Reached maximum trainings (#{MAX_TRAININGS_PER_URL})"
        elsif redundant_path?( @parser.url )
            skip_message = 'Matched redundancy filters'
        elsif skip_resource?( response )
            skip_message = 'Matched exclusion criteria'
        end

        if skip_message
            print_verbose "#{skip_message}, skipping: #{@parser.url}"
            return false
        end

        analyze response
        true
    rescue => e
        print_error e.to_s
        print_error_backtrace e
    end

    # Sets the current working page and inits the element DB.
    #
    # @param    [Arachni::Page]    page
    def page=( page )
        init_db_from_page page
        @page = page
    end
    alias :init :page=

    def on_new_page( &block )
        @on_new_page_blocks << block
    end

    private

    # Analyzes a response looking for new links, forms and cookies.
    #
    # @param   [Arachni::HTTP::Response]  response
    def analyze( response )
        print_debug "Started for response with request ID: ##{response.request.id}"

        new_elements = {
            cookies: find_new( :cookies )
        }

        # if the response body is the same as the page body and
        # no new cookies have appeared there's no reason to analyze the page
        if response.body == @page.body && !@updated && @page.url == @parser.url
            print_debug 'Page hasn\'t changed.'
            return
        end

        # TODO: Maybe not only return new elements because it messes up
        # the page integrity. Pass the page along if it has new elements and then
        # clear the caches.
        [ :forms, :links ].each { |type| new_elements[type] = find_new( type ) }

        if @updated
            @trainings_per_url[@parser.url] += 1

            page = @parser.page

            # Only keep new elements.
            new_elements.each { |type, elements| page.send( "#{type}=", elements ) }

            @on_new_page_blocks.each { |block| block.call page }

            # feed the page back to the framework
            @framework.push_to_page_queue( page )

            @updated = false
        end

        print_debug 'Training complete.'
    end

    def find_new( element_type )
        elements, count = send( "update_#{element_type}".to_sym, @parser.send( element_type ) )
        return [] if count == 0

        @updated = true
        print_info "Found #{count} new #{element_type}."

        elements
    end

end
end
