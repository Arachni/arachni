=begin
                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

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
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
#
class Trainer
    
    include Output
    include ElementDB
    include Singleton

    attr_writer   :page
    attr_accessor :http

    def initialize
      @opts     = Options.instance
      @analyzer = Analyzer.new( @opts )
      @updated = false
    end

    #
    # Passes the reponse to {#analyze} for analysis
    #
    # @param  [Typhoeus::Response]  res
    # @param  [Bool]  redir  was the response forcing a redirection?
    #
    def add_response( res, redir = false )
        analyze( [ res, redir ] )
    end
    
    #
    # Returns an updated {Page} object or nil if there waere no updates
    #
    # @return  [Page]
    #
    def page
        if( @updated  )
              @updated = false
              # page = @page.dup
              # @page = nil
              return  @page
          else
              return nil
        end
    end

    
    private
    
    #
    # Analyzes a response looking for new links, forms and cookies.
    #
    # @param   [Array]  res   {Typhoeus::Response}, Bool
    #
    def analyze( res )
        
        print_debug( 'Started...' )
        
        forms, form_cnt = train_forms( res[0] )
        links, link_cnt = train_links( res[0], res[1] )
        
        cookies, cookie_cnt = train_cookies( res[0] )
        
        if ( form_cnt > 0 )
            @page.elements['forms'] = forms.flatten
            @updated = true
            
            print_debug( 'Found ' + form_cnt.to_s + ' new forms.' )
        end
        
        if ( link_cnt > 0 )
            @page.elements['links'] = links.flatten
            @updated = true
            
            print_debug( 'Found ' + link_cnt.to_s + ' new links.' )
        end
        
        if ( cookie_cnt > 0 )
            @page.elements['cookies'] = cookies.flatten
            @updated = true
            
            print_debug( 'Found ' + cookie_cnt.to_s + ' new cookies.' )
        end

        print_debug( 'Training complete.' )
    end
    
    def train_forms( res )
        return if !@opts.audit_forms
        
        @analyzer.url = res.effective_url.clone
        forms = @analyzer.get_forms( res.body ).clone
        
        return update_forms( forms )
    end
    
    def train_links( res, redir = false )
        return if !@opts.audit_links
        
        @analyzer.url = res.effective_url.clone

        if( redir )
            @analyzer.url = URI( @page.url ).
              merge( URI( URI.escape( res.request.url ) ) ).to_s
        end

        links   = @analyzer.get_links( res.body ).clone
        
        if( redir )
            links.push( {
                'href' => @analyzer.url,
                'vars' => @analyzer.get_link_vars( @analyzer.url )
            } )

        end
        
        return update_links( links )
        
    end
    
    def train_cookies( res )
        cookies = @analyzer.get_cookies( res.headers_hash['Set-Cookie'].to_s ).clone        
        return update_cookies( cookies )
    end

    
    def self.info
      { :name  => 'Trainer' }
    end
    
end
end
end
