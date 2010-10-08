=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end
module Arachni
module Module

#
# Holds a database of all auditable elements of the current page,<br/>
# including elements that have appeared dynamically during the audit.
#
# The database is updated by the {Trainer}.
#
# For each page that is audited the database is reset.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
#
module ElementDB
  
    #
    # page forms
    #
    @@forms    ||= []
    
    #
    # page links
    #
    @@links    ||= []
    
    #
    # page cookies
    #
    @@cookies  ||= []
    
    #
    # used to synchronize @@forms updates
    #
    @@form_mutex   ||= Mutex.new
    
    #
    # used to synchronize @@links updates
    #
    @@link_mutex   ||= Mutex.new
    
    #
    # used to synchronize @@cookies updates
    #
    @@cookie_mutex ||= Mutex.new

    def init_seed( seed )
        @@seed = seed
    end
    
    #
    # Initializes @@forms with the cookies found during the crawl/analysis
    #
    def init_forms( forms )
      @@forms = forms
    end
    
    #
    # Initializes @@links with the links found during the crawl/analysis
    #
    def init_links( links )
      @@links = links
    end
    
    #
    # Initializes @@cookies with the cookies found during the crawl/analysis
    #
    def init_cookies( cookies )
      @@cookies = cookies
      
      cookie_jar = @http.parse_cookie_str( @http.init_headers['cookie'] )
      cookie_jar = get_cookies_simple( @@cookies ).merge( cookie_jar )
      @http.set_cookies( cookie_jar )

    end
    
    #
    # Updates @@forms wth new forms that may have dynamically appeared<br/>
    # after analyzing the HTTP responses during the audit.
    #
    # @param    [Array<Hash>] forms    the return object of {Analyzer#get_forms}
    #
    def update_forms( forms )
        
        return [], 0 if forms.size == 0
        
        form_cnt = 0
        @new_forms ||= []
        # @@form_mutex.synchronize {
          
            forms.each {
                |form|
                
                next if form['attrs']['action'].include?( @@seed )
                next if form['auditable'].size == 0
            
                if !(index = forms_include?( form ) )
                    @@forms << form
                    @new_forms << form
                    form_cnt += 1 
                end
            
            }
        # }
        return @new_forms, form_cnt
        
    end

    #
    # Updates @@links wth new links that may have dynamically appeared<br/>
    # after analyzing the HTTP responses during the audit.
    #
    # @param    [Array<Hash>]    links  the return object of {Analyzer#get_links}
    #
    def update_links( links )
      return [], 0 if links.size == 0
      
      link_cnt = 0
      @new_links ||= []
      # @@link_mutex.synchronize {
          links.each {
              |link|
              
              next if !link
              next if !link['href']
              next if link['href'].include?( @@seed )
              
              if( !@@links.include?( link ) )
                  @@links << link
                  @new_links << link
                  link_cnt += 1
              end
          }
          
          return @new_links, link_cnt
      # }
    end

    #
    # Updates @@cookies wth new cookies that may have dynamically appeared<br/>
    # after analyzing the HTTP responses during the audit.
    #
    # @param    [Array<Hash>]   cookies   the return object of {Analyzer#get_cookies}
    #
    def update_cookies( cookies )
        return [], 0 if cookies.size == 0
            
        cookie_cnt = 0
        @new_cookies ||= []
        
        # @@cookie_mutex.synchronize {
            cookies.each_with_index {
                |cookie|
                
                @@cookies.each_with_index {
                    |page_cookie, i|
    
                    if( page_cookie['name'] == cookie['name'] )
                        @@cookies[i] = cookie
                    else
                        @new_cookies << cookie
                        cookie_cnt += 1
                    end
                }
    
            }
            
            @@cookies.flatten!
            
            @@cookies |= @new_cookies
            
            # if( @@cookies.length == 0 )
            #     @@cookies = new_cookies = cookies
            # end
    
            cookie_jar = @http.parse_cookie_str( @http.init_headers['cookie'] )
            cookie_jar = get_cookies_simple( @@cookies ).merge( cookie_jar )
            
            @http.set_cookies( cookie_jar )
        # }
        return [ @@cookies, cookie_cnt ]
    end

    private

    def forms_include?( form )
        @@forms.each_with_index {
            |page_form, i|
            return i if( form_id( form ) == form_id( page_form ) )
                    
        }
        return false
    end
    
    #
    # Returns a form ID string disregarding the values of their input fields.<br/>
    # Used to compare forms in {#update_forms}.
    #
    # @param    [Hash]    form
    #
    def form_id( form )
      
        cform = form.dup
        id    = cform['attrs'].to_s
        
        cform['auditable'].map {
            |item|
            citem = item.clone
            citem.delete( 'value' )
            id +=  citem.to_s
        }
        return id
    end

    #
    # Returns cookies as a name=>value hash
    #
    # @return    [Hash]    the cookie attributes, values, etc
    #
    def get_cookies_simple( incookies = nil )
        cookies = Hash.new( )
        
        incookies = get_cookies( ) if !incookies
        
        incookies.each {
            |cookie|
            cookies[cookie['name']] = cookie['value']
        }
        
        return cookies if !@page.cookiejar
        @page.cookiejar.merge( cookies )
    end


end

end
end
