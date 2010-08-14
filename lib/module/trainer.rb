=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end
module Arachni
module Module

#
# Trainer module
#
# Included by {Module::Base}.<br/>
# Includes trainer methods used to updated the {Page} in case any<br/>
# new elements appear dynamically during the audit.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1-pre
#
module Trainer

    private
    
    
    #
    # This is used to train Arachni.
    #
    # It will be called to analyze every HTTP response during the audit,<br/>
    # detect any changes our input may have caused to the web app<br/>
    # and make the module aware of new attack vectors that may present themselves.
    #
    # @param    [Net::HTTPResponse]  res    the HTTP response
    # @param    [String]    url     provide a new url in case our request
    #                                 caused a redirection
    #
    def train( res, url = nil )

        opts = Options.instance
        analyzer = Analyzer.new( opts )

        analyzer.url = @page.url.clone

        if( url )
            analyzer.url = URI( @page.url ).
            merge( URI( URI.escape( url ) ) ).to_s
        end

        links   = analyzer.get_links( res.body ).clone if opts.audit_links
        forms   = analyzer.get_forms( res.body ).clone if opts.audit_forms
        cookies = analyzer.get_cookies( res.to_hash['set-cookie'].to_s ).clone

        if( url )
            links.push( {
                'href' => analyzer.url,
                'vars' => analyzer.get_link_vars( analyzer.url )
            } )
        end

        @form_train_cnt ||= 0

        old_count = train_elem_count( )
        @page.elements['links']   = train_links( links )
        @page.elements['forms']   = train_forms( forms )
        @page.elements['cookies'] = train_cookies( cookies )
        new_count = train_elem_count( )
        
        if( new_count > old_count)
            update_form_queue( @page.elements['forms'] )
            update_link_queue( @page.elements['links'] )
            update_cookie_queue( @page.elements['cookies'] )
                
            print_info( "Arachni has been trained for: #{analyzer.url}" )
        end

    end

    #
    # Updates the forms in {Page#elements}
    #
    # @param    [Array<Hash>] forms    the return object of {Analyzer#get_forms}
    # @return    [Array<Hash>]    the updated forms
    #
    def train_forms( forms )

        return @page.elements['forms'] if @form_train_cnt > 20
        
        if !forms then return @page.elements['forms'] end
            
        new_forms = []
        forms.each {
            |form|

            next if form['attrs']['action'].include?( '__arachni__' )
            next if form['auditable'].size == 0
                
            @page.elements['forms'].each_with_index {
                |page_form, i|

                if( form_id( form ) == form_id( page_form ) )
                    page_form = form
                else
                    new_forms << form
                    @form_train_cnt += 1
                end
            }

        }

        return @page.elements['forms'] | new_forms
    end

    #
    # Returns a form ID string disregarding the values of their input fields.<br/>
    # Used to compare forms in {#train_forms}.
    #
    # @param    [Hash]    form
    # @return    [String]
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
    # Updates the links in {Page#elements}
    #
    # @param    [Array<Hash>]    links  the return object of {Analyzer#get_links}
    # @return    [Array<Hash>]    the updated links
    #
    def train_links( links )
        if !links then return @page.elements['links'] end
            
        links.each {
            |link|
            
            if !@page.elements['links'].include?( link )
                @page.elements['links'] << link
            end
        }

        return @page.elements['links']
    end

    #
    # Updates the cookies in {Page#elements}
    #
    # @param    [Array<Hash>]   cookies   the return object of {Analyzer#get_cookies}
    # @return    [Array<Hash>]    the updated cookies
    #
    def train_cookies( cookies )
        if !cookies then return @page.elements['cookies'] end
            
        new_cookies = []
        cookies.each_with_index {
            |cookie|
            
            @page.elements['cookies'].each_with_index {
                |page_cookie, i|

                if( page_cookie['name'] == cookie['name'] )
                    @page.elements['cookies'][i] = cookie
                else
                    new_cookies << cookie
                end
            }

        }

        @page.elements['cookies'] |= new_cookies

        if( @page.elements['cookies'].length == 0 )
            @page.elements['cookies'] = new_cookies = cookies
        end

        cookie_jar = @http.parse_cookie_str( @http.init_headers['cookie'] )
        cookie_jar = cookie_jar.merge( get_cookies_simple( @page.elements['cookies'] ) )
        @http.set_cookies( cookie_jar )

        return @page.elements['cookies']
    end

    #
    # Returns a count of all elements in {Page}, except for headers
    #
    # @return    [Integet]
    #
    def train_elem_count
        return @page.elements['links'].clone.length +
            @page.elements['forms'].clone.length +
            @page.elements['cookies'].clone.length
    end

end
end
end
