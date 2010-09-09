=begin
                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules
module Audit

#
# Path Traversal audit module.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
# @see http://cwe.mitre.org/data/definitions/22.html    
# @see http://www.owasp.org/index.php/Path_Traversal
# @see http://projects.webappsec.org/Path-Traversal
#
class PathTraversal < Arachni::Module::Base

    include Arachni::Module::Registrar

    def initialize( page )
        super( page )

        @results    = []
    end
    
    def prepare( )
        @__trv =  '../../../../../../../../../../../../../../../../'
        @__ext = [
            "",
            "\0.htm",
            "\0.html",
            "\0.asp",
            "\0.aspx",
            "\0.php",
            "\0.txt",
            "\0.gif",
            "\0.jpg",
            "\0.jpeg",
            "\0.png",
            "\0.css"
        ]
        
        @__params = [
            {
                'value'  => 'etc/passwd',
                'regexp' => /\w+:.+:[0-9]+:[0-9]+:.+:[0-9a-zA-Z\/]+/im
            },
            {
                'value'  => 'boot.ini',
                'regexp' => /\[boot loader\](.*)\[operating systems\]/im
            }
          
        ]
    end

    def run( )

        @__params.each {
            |param|
            
            @__ext.each {
                |ext|
                
                injection_str = @__trv + param['value'] + ext
                
                #
                # This module needs some optimizations
                # so we'll bypass the standard framework audit methods
                # and work on our own
                #
                
                __audit_forms( injection_str ) {
                    |url, res, var|
                    __log_results( Vulnerability::Element::FORM, var,
                      res, url, injection_str, param['regexp'] )
                }
                
                __audit_links( injection_str ) {
                    |url, res, var|
                    __log_results( Vulnerability::Element::LINK, var,
                      res, url, injection_str, param['regexp'] )
                }
                        
                __audit_cookies( injection_str ) {
                    |url, res, var|
                    __log_results( Vulnerability::Element::COOKIE, var,
                      res, url, injection_str, param['regexp'] )
                }
            }
        }
        
        # register our results with the system
        register_results( @results )
    end

    def __audit_links( injection_str, &block )

        results = []
        
        work_on_links {
            |link|
            
            url       = link['href']
            link_vars = link['vars']
            
            # if we don't have any auditable elements just return
            if !link_vars then next end

            # iterate through all url vars and audit each one
            inject_each_var( link_vars, injection_str, false ).each {
                |vars|
    
                audit_id = "#{self.class.info['Name']}:" +
                    "#{url}:#{Vulnerability::Element::LINK}:" +
                    "#{vars['altered'].to_s}=#{vars['hash'].to_s}"
                
                next if @@audited.include?( audit_id )

                # tell the user what we're doing
                print_status( "Auditing link var '" +
                    vars['altered'] + "' of " + url )
                
                if( URI( link['href'] ).query ) 
                    url = link['href'].gsub( Regexp.new( URI( link['href'] ).query ), '' )
                else
                    url = link['href'].dup
                end

                # audit the url vars
                res = @http.get( url, vars['hash'] )
                @@audited << audit_id
                
                url = link['href'].dup
                
                # something might have gone bad,
                # make sure it doesn't ruin the rest of the show...
                if !res then next end
                
                # call the passed block
                if block_given?
                    block.call( url, res, vars['altered'] )
                    next
                end
                
            }
        }    
    end

    def __audit_forms( injection_str, &block )
        
        results = []
        
        work_on_forms {
            |orig_form|
            form = get_form_simple( orig_form )

            next if !form
            
            url    = form['attrs']['action']
            method = form['attrs']['method']
                
            # iterate through each auditable element
            inject_each_var( form['auditable'], injection_str, false ).each {
                |input|

                audit_id = "#{self.class.info['Name']}:" +
                    "#{url}:" +
                    "#{Vulnerability::Element::FORM}:" + 
                    "#{input['altered'].to_s}=#{input['hash'].to_s}"
                
                next if @@audited.include?( audit_id )
                
                # inform the user what we're auditing
                print_status( "Auditing form input '" +
                    input['altered'] + "' with action " + url )

                if( method != 'get' )
                    res = @http.post( url, input['hash'] )
                else
                    res = @http.get( url, input['hash'] )
                end
                
                @@audited << audit_id
                
                # make sure that we have a response before continuing
                if !res then next end
                
                # call the block, if there's one
                if block_given?
                    block.call( url, res, input['altered'] )
                    next
                end

            }
        }
    end

    def __audit_cookies( injection_str, &block )
        
        results = []
        
        # iterate through each cookie
        work_on_cookies {
            |orig_cookie|
        inject_each_var( get_cookie_simple( orig_cookie ), injection_str, false ).each {
            |cookie|

            next if Options.instance.exclude_cookies.include?( cookie['altered'] )
            
            audit_id = "#{self.class.info['Name']}:" +
                "#{@page.url}:#{Vulnerability::Element::COOKIE}:" +
                "#{cookie['altered'].to_s}=#{cookie['hash'].to_s}"
            
            next if @@audited.include?( audit_id )

            # tell the user what we're auditing
            print_status( "Auditing cookie '" +
                cookie['altered'] + "' of " + @page.url )

            # make a get request with our cookies
            res = @http.cookie( @page.url, cookie['hash'], nil )
                
            @@audited << audit_id

            # check for a response
            if !res then next end
            
            if block_given?
                block.call( @page.url, res, cookie['altered'] )
                next
            end
            
        }
        }
    end

    
    def self.info
        {
            'Name'           => 'PathTraversal',
            'Description'    => %q{Path Traversal module.},
            'Elements'       => [ 
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE
            ],
            'Author'         => 'zapotek',
            'Version'        => '0.1.1',
            'References'     => {
                'OWASP' => 'http://www.owasp.org/index.php/Path_Traversal',
                'WASC'  => 'http://projects.webappsec.org/Path-Traversal'
            },
            'Targets'        => { 'Generic' => 'all' },
                
            'Vulnerability'   => {
                'Name'        => %q{Path Traversal},
                'Description' => %q{Improper limitation of a pathname to a restricted directory.},
                'CWE'         => '22',
                'Severity'    => Vulnerability::Severity::MEDIUM,
                'CVSSV2'       => '4.3',
                'Remedy_Guidance'    => '',
                'Remedy_Code' => '',
            }

        }
    end
    
    def __log_results( where, var, res, url, injection_str, regexp )

        if ( ( match = res.body.scan( regexp )[0] ) && match.size > 0 )
            
            injection_str = URI.escape( injection_str ) 
            
            # append the result to the results hash
            @results << Vulnerability.new( {
                    'var'          => var,
                    'url'          => url,
                    'injected'     => injection_str,
                    'id'           => 'n/a',
                    'regexp'       => regexp.to_s,
                    'regexp_match' => match,
                    'elem'         => where,
                    'response'     => res.body,
                    'headers'      => {
                        'request'    => get_request_headers( ),
                        'response'   => get_response_headers( res ),    
                   }

                }.merge( self.class.info )
            )
                
            # inform the user that we have a match
            print_ok( "In #{where} var '#{var}' ( #{url} )" )
            
            # give the user some more info if he wants 
            print_verbose( "Injected str:\t" + injection_str )    
            print_verbose( "Matched regex:\t" + regexp.to_s )
            print_verbose( '---------' ) if only_positives?
    
        end
        
    end


end
end
end
end
