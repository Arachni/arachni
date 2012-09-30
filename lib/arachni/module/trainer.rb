=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni

require Options.dir['lib'] + 'module/element_db'
require Options.dir['lib'] + 'module/output'

module Module

#
# Trainer class
#
# Analyzes key HTTP responses looking for new auditable elements.
#
# @author Tasos Laskos <tasos.laskos@gmail.com>
#
class Trainer
    include Output
    include ElementDB
    include Utilities

    attr_reader :page

    # @param    [Arachni::Options]  opts
    def initialize( opts )
        @opts    = opts
        @updated = false

        @pages = []
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

    #
    # Flushes the page buffer
    #
    # @return   [Array<Arachni::Page>]
    #
    def flush
        pages = @pages.dup
        @pages.clear
        pages
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

        @parser = Parser.new( res )
        return false if !@parser.text? || @parser.skip?( @parser.url )

        analyze( res )
        true
    rescue => e
        print_error( e.to_s )
        print_error_backtrace( e )
    end
    alias :<< :push

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

            @pages << Page.new( page_data )

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
end
