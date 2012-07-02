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

require Arachni::Options.instance.dir['lib'] + 'module/element_db'
require Arachni::Options.instance.dir['lib'] + 'module/output'

module Arachni
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
        @opts     = opts
        @updated  = false

        @pages = []
    end

    #
    # Inits the element DB and sets the current working page.
    #
    # @param    [Arachni::Parser::Page]    page
    #
    def init_from_page( page )
        init_db_from_page( page )
        self.page = page
    end

    #
    # Sets the current working page.
    #
    # @param    [Arachni::Parser::Page]    page
    #
    def page=( page )
        @page = page.deep_clone
    end

    #
    # Flushes the page buffer
    #
    # @return   [Array<Arachni::Parser::Page>]
    #
    def flush_pages
        pages  = @pages.dup
        @pages = []
        pages
    end

    #
    # Passes the response on for analysis.
    #
    # If the response contains new elements it creates a new page
    # with those elements and pushes it a buffer.
    #
    # These new pages can then be retrieved by flushing the buffer (#flush_pages).
    #
    # @param  [Typhoeus::Response]  res
    #
    def add_response( res )
        if !@page
            print_debug 'No seed page assigned yet.'
            return
        end

        @parser = Parser.new( @opts, res )
        return false if !@parser.text? || @parser.skip?( @parser.url )

        analyze!( res )
        true
    rescue => e
        print_error( e.to_s )
        print_error_backtrace( e )
    end

    private

    #
    # Analyzes a response looking for new links, forms and cookies.
    #
    # @param   [Typhoeus::Response]  res
    #
    def analyze!( res )
        print_debug "Started for response with request ID: ##{res.request.id}"

        page_data           = @page.to_hash
        page_data[:cookies] = train_cookies

        # if the response body is the same as the page body and
        # no new cookies have appeared there's no reason to analyze the page
        if res.body == @page.body && !@updated && @page.url == @parser.url
            print_debug 'Page hasn\'t changed.'
            return
        end

        page_data[:forms] = train_forms
        page_data[:links] = train_links

        if @updated
            page_data[:url]              = @parser.url
            page_data[:query_vars]       = @parser.link_vars( @parser.url )
            page_data[:code]             = res.code
            page_data[:method]           = res.request.method.to_s.upcase
            page_data[:body]             = res.body
            page_data[:doc]              = @parser.doc
            page_data[:response_headers] = res.headers_hash

            @pages << Arachni::Parser::Page.new( page_data )

            @updated = false
        end

        print_debug 'Training complete.'
    end

    def train_forms
        cforms, form_cnt = update_forms( @parser.forms )
        return [] if form_cnt == 0

        @updated = true
        print_info "Found #{form_cnt} new forms."

        prepare_new_elements( cforms )
    end

    def train_links
        links, link_cnt = update_links( @parser.links )
        return [] if link_cnt == 0

        @updated = true
        print_info "Found #{link_cnt} new links."

        prepare_new_elements( links )
    end

    def train_cookies
        ccookies, cookie_cnt = update_cookies( @parser.cookies )
        return [] if cookie_cnt == 0

        @updated = true
        print_info "Found #{cookie_cnt} new cookies."

        prepare_new_elements( ccookies )
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
