=begin
                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end
module Arachni
module Module

#
# Holds a database of all auditable elements in the current page,<br/>
# including elements that have appeared dynamically during the audit.
#
# The database is updated by the {Trainer}.
#
# For each page that is audited the database is reset by the {Base} module.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
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
    # This method passes the block with each form in the page.
    #
    # Unlike {Base#get_forms} this method is "trainer-aware",<br/>
    # meaning that should the page dynamically change and a new form <br/>
    # presents itself during the audit Arachni will see it and pass it.
    #
    # @param    [Proc]    block
    #
    def work_on_forms( &block )
        return if !Options.instance.audit_forms
        # @@forms.each { |form| block.call( form ) }
        
        t = Thread.new do
            sz = @@forms.size
            while( form = @@forms[sz-1] )
                block.call( form )
                sz -= 1
            end
        end
        
        t.join
    end

    #
    # This method passes the block with each link in the page.
    #
    # Unlike {Base#get_links} this method is "trainer-aware",<br/>
    # meaning that should the page dynamically change and a new link <br/>
    # presents itself during the audit Arachni will see it and pass it.
    #
    # @param    [Proc]    block
    #
    def work_on_links( &block )
        return if !Options.instance.audit_links
        # @@links.each { |link| block.call( link ) }
        
        t = Thread.new do
            sz = @@links.size
            while( link = @@links[sz-1] )
                block.call( link )
                sz -= 1
            end
        end
        
        t.join
    end
    
    #
    # This method passes the block with each cookie in the page.
    #
    # Unlike {Base#get_cookies} this method is "trainer-aware",<br/>
    # meaning that should the page dynamically change and a new cookie <br/>
    # presents itself during the audit Arachni will see it and pass it.
    #
    # @param    [Proc]    block
    #
    def work_on_cookies( &block )
        return if !Options.instance.audit_cookies
        # @@cookies.each { |cookie| block.call( cookie ) }
        
        t = Thread.new do
            sz = @@cookies.size
            while( cookie = @@cookies[sz-1] )
                block.call( cookie )
                sz -= 1
            end
        end
        
        t.join
    end
      
    #
    # Updates @@forms wth new forms that may have dynamically appeared<br/>
    # after analyzing the HTTP responses during the audit.
    #
    # @param    [Array<Hash>] forms    the return object of {Analyzer#get_forms}
    #
    def update_forms( forms )
        
        return if forms.size == 0
        
        new_forms = []
        @@form_mutex.synchronize {
          
            if( @@forms.empty? )
                @@forms = forms
                return 
            end
            
            forms.each {
                |form|
                
                next if form['attrs']['action'].include?( '__arachni__' )
                next if form['auditable'].size == 0
            
                if ! (index = forms_include?( form ) )
                    @@forms << form 
                else
                    @@forms[index] = form
                end
            
            }
        }
        
        
    end

    #
    # Updates @@links wth new links that may have dynamically appeared<br/>
    # after analyzing the HTTP responses during the audit.
    #
    # @param    [Array<Hash>]    links  the return object of {Analyzer#get_links}
    #
    def update_links( links )
      return if links.size == 0
      
      @@link_mutex.synchronize {
          links.each {
              |link|
              
              next if !link
              next if !link['href']
              next if link['href'].include?( '__arachni__' )
                
              @@links |= [link]
          }
      }
    end

    #
    # Updates @@cookies wth new cookies that may have dynamically appeared<br/>
    # after analyzing the HTTP responses during the audit.
    #
    # @param    [Array<Hash>]   cookies   the return object of {Analyzer#get_cookies}
    #
    def update_cookies( cookies )
        return if cookies.size == 0
            
        new_cookies = []
        
        @@cookie_mutex.synchronize {
            cookies.each_with_index {
                |cookie|
                
                @@cookies.each_with_index {
                    |page_cookie, i|
    
                    if( page_cookie['name'] == cookie['name'] )
                        @@cookies[i] = cookie
                    else
                        new_cookies << cookie
                    end
                }
    
            }
    
            @@cookies |= new_cookies
    
            if( @@cookies.length == 0 )
                @@cookies = new_cookies = cookies
            end
    
            cookie_jar = @http.parse_cookie_str( @http.init_headers['cookie'] )
            cookie_jar = get_cookies_simple( @@cookies ).merge( cookie_jar )
            
            @http.set_cookies( cookie_jar )
        }
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

end

end
end
