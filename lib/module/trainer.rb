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

    attr_accessor :page
    attr_accessor :http

    def initialize
      @opts          = Options.instance
      @analyzer      = Analyzer.new( @opts )
      @@response_q ||= Queue.new
    end

    def add_response( res, redir = false )
        @@response_q << [res, redir]
    end
    
    def analyze
        
        print_status( 'Started...' )
        
        forms = []
        links = []
        cookies = []
        @@response_q << nil
        while( res = @@response_q.pop )
             form = train_forms( res[0] )
             forms << form if form
             
            link = train_links( res[0], res[1] )
            links << link if link
            
            cookie, cnt_new_cookies = train_cookies( res[0] )
            cookies << cookie if cnt_new_cookies
        end
        
        updated = false
        
        forms.flatten!
        if ( !forms.empty? )
            @page.elements['forms'] = forms
            updated = true
            
            print_status( 'Found ' + forms.size.to_s + ' new forms.' )
        end
        
        links.flatten!
        if ( !links.empty? )
            @page.elements['links'] = links
            updated = true
            
            print_status( 'Found ' + links.size.to_s + ' new links.' )
        end
        
        cookies.flatten!
        if ( cnt_new_cookies && cnt_new_cookies > 0 )
            @page.elements['cookies'] = cookies
            updated = true
            
            print_status( 'Found ' + cnt_new_cookies.to_s + ' new cookies.' )
        end

          
        if( updated )
            ret =  @page.dup
        else
            ret =  nil
            print_status( 'No new elements found.' )
        end
        
        print_status( 'Training complete.' )
        return ret
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
      { 'Name' => 'Trainer' }
    end
    
end
end
end
