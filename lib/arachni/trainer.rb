=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

require Options.dir['lib'] + 'element_filter'
require Options.dir['lib'] + 'module/output'

#
# Trainer class
#
# Analyzes key HTTP responses looking for new auditable elements.
#
# @author Tasos Laskos <tasos.laskos@gmail.com>
#
class Trainer
    include Module::Output
    include ElementFilter
    include Utilities

    MAX_TRAININGS_PER_URL = 25

    # @param    [Arachni::Framework]  framework
    def initialize( framework )
        @framework  = framework
        @updated    = false

        @on_new_page_blocks = []
        @trainings_per_url  = Hash.new( 0 )

        # get us setup using the page that is being audited as a seed page
        framework.on_audit_page { |page| self.page = page }

        HTTP.add_on_queue do |req, _|
            next if !req.train?

            req.on_complete( true ) do |res|
                # handle redirections
                if res.redirection? && res.location.is_a?( String )
                    reference_url = @page ? @page.url : framework.opts.url
                    HTTP.get( to_absolute( res.location, reference_url ) ) do |res2|
                        push( res2 )
                    end
                else
                    push( res )
                end
            end
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
    # @param  [Typhoeus::Response]  res
    #
    def push( res )
        if !@page
            print_debug 'No seed page assigned yet.'
            return
        end

        if @framework.link_count_limit_reached?
            print_info 'Link count limit reached, skipping analysis.'
            return
        end

        @parser = Parser.new( res )

        return false if !@parser.text? ||
            @trainings_per_url[@parser.url] >= MAX_TRAININGS_PER_URL ||
            redundant_path?( @parser.url ) || skip_resource?( res )

        analyze( res )
        true
    rescue => e
        print_error( e.to_s )
        print_error_backtrace( e )
    end

    #
    # Sets the current working page and inits the element DB.
    #
    # @param    [Arachni::Page]    page
    #
    def page=( page )
        init_db_from_page( page )
        @page = page.deep_clone
    end
    alias :init :page=

    def on_new_page( &block )
        @on_new_page_blocks << block
    end

    private

    #
    # Analyzes a response looking for new links, forms and cookies.
    #
    # @param   [Typhoeus::Response]  res
    #
    def analyze( res )
        print_debug "Started for response with request ID: ##{res.request.id}"

        page_data           = @page.to_hash
        page_data[:cookies] = find_new( :cookies )

        # if the response body is the same as the page body and
        # no new cookies have appeared there's no reason to analyze the page
        if res.body == @page.body && !@updated && @page.url == @parser.url
            print_debug 'Page hasn\'t changed.'
            return
        end

        [ :forms, :links ].each { |type| page_data[type] = find_new( type ) }

        if @updated
            page_data[:url]              = @parser.url
            page_data[:query_vars]       = @parser.link_vars( @parser.url )
            page_data[:code]             = res.code
            page_data[:method]           = res.request.method.to_s.upcase
            page_data[:body]             = res.body
            page_data[:doc]              = @parser.doc
            page_data[:response_headers] = res.headers_hash

            @trainings_per_url[@parser.url] += 1

            page = Page.new( page_data )

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

        prepare_new_elements( elements )
    end

    def prepare_new_elements( elements )
        elements.flatten.map { |elem| elem.override_instance_scope; elem }
    end

    def self.info
        { name: 'Trainer' }
    end

end
end
