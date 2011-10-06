=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require Arachni::Options.instance.dir['lib'] + 'module/element_db'
require Arachni::Options.instance.dir['lib'] + 'module/output'

module Arachni
module Module

#
# Trainer class
#
# Analyzes all HTTP responses looking for new auditable elements.
#
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2.1
#
class Trainer

    include Output
    include ElementDB
    include Utilities

    attr_writer   :page
    attr_accessor :http
    attr_accessor :parser

    def initialize
      @opts     = Options.instance
      @updated  = false
    end

    #
    # Passes the reponse to {#analyze} for analysis
    #
    # @param  [Typhoeus::Response]  res
    # @param  [Bool]  redir  was the response forcing a redirection?
    #
    def add_response( res, redir = false )

        # non text files won't contain any auditable elements
        type = @http.class.content_type( res.headers_hash )
        if type.is_a?( String) && !type.substring?( 'text' )
            return false
        end

        @parser = Parser.new( Options.instance, res )
        @parser.url = @page.url

        begin
            url = @parser.to_absolute( res.effective_url )

            return if !follow?( url )

            analyze( [ res, redir ] )

        rescue Exception => e
            print_error( "Invalid URL, probably broken redirection. Ignoring..." )
            raise e
        end

    end

    def follow?( url )
        !@parser.skip?( url )
    end

    #
    # Returns an updated {Arachni::Parser::Page} object or nil if there waere no updates
    #
    # @return  [Page]
    #
    def page
        if( @updated  )
              @updated = false
              return  @page
          else
              return nil
        end
    end


    #
    # Analyzes a response looking for new links, forms and cookies.
    #
    # @param   [Typhoeus::Response, Bool]  res
    #
    def analyze( res )

        print_debug( 'Started for response with request ID: #' +
          res[0].request.id.to_s )

        @parser.url = @parser.to_absolute( url_sanitize( res[0].effective_url ) )

        train_cookies( res[0] )

        # if the response body is the same as the page body and
        # no new cookies have appeared there's no reason to analyze the page
        if( res[0].body == @page.html && !@updated )
            print_debug( 'Page hasn\'t changed, skipping...' )
            return
        end

        train_forms( res[0] )
        train_links( res[0], res[1] )

        if( @updated )
            @page.html = res[0].body.dup

            begin
                url           = res[0].request.url
                # prepare the page url
                @parser.url = @parser.to_absolute( url )
            rescue Exception => e
                print_error( "Invalid URL, probably broken redirection. Ignoring..." )
                # raise e
            end

            @page.response_headers    = res[0].headers_hash
            @page.query_vars = @parser.link_vars( @parser.url ).dup
            @page.url        = @parser.url.dup
            @page.code       = res[0].code
            @page.method     = res[0].request.method.to_s.upcase

        end

        print_debug( 'Training complete.' )
    end

    private

    def train_forms( res )
        return [], 0 if !@opts.audit_forms

        forms = @parser.forms( ).clone
        cforms, form_cnt = update_forms( forms )

        if ( form_cnt > 0 )
            @page.forms = cforms.flatten
            @updated = true

            print_debug( 'Found ' + form_cnt.to_s + ' new forms.' )
        else
            @page.forms = forms
        end

    end

    def train_links( res, redir = false )
        return [], 0  if !@opts.audit_links

        links   = @parser.links.clone

        if( redir )

            url = @parser.to_absolute( url_sanitize( res.effective_url ) )
            links << Arachni::Parser::Element::Link.new( url, {
                'href' => url,
                'vars' => @parser.link_vars( url )
            } )
        end

        clinks, link_cnt = update_links( links )

        if ( link_cnt > 0 )
            @page.links = clinks.flatten
            @updated = true

            print_debug( 'Found ' + link_cnt.to_s + ' new links.' )
        else
            @page.links = links
        end

    end

    def train_cookies( res )

        cookies = @parser.cookies.clone
        ccookies, cookie_cnt = update_cookies( cookies )

        if ( cookie_cnt > 0 )
            @page.cookies = ccookies.flatten
            @updated = true

            print_debug( 'Found ' + cookie_cnt.to_s + ' new cookies.' )
        else
            @page.cookies = cookies
        end

    end

    def self.info
      { :name  => 'Trainer' }
    end

end
end
end
