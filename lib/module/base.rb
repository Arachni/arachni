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
# Arachni's base module class<br/>
# To be extended by Arachni::Modules.
#    
# Defines basic structure and provides utilities to modules.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1-pre
# @abstract
#
class Base

    #
    # Arachni::HTTP instance for the modules
    #
    # @return [Arachni::HTTP]
    #
    attr_reader :http

    #
    # Arachni::Page instance
    #
    # @return [Page]
    #
    attr_reader :page

    #
    # Initializes the module attributes and HTTP client
    #
    # @param  [Page]  page
    #
    def initialize( page )
        
        @page = page
        @http = Arachni::Module::HTTP.new( @page.url )
            
        if( @page.cookiejar )
            @http.set_cookies( @page.cookiejar )
        end
        
    end

    #
    # ABSTRACT - OPTIONAL
    #
    # It provides you with a way to setup your module's data and methods.
    #
    def prepare( )
    end

    #
    # ABSTRACT - REQUIRED
    #
    # This is used to deliver the module's payload whatever it may be.
    #
    def run( )
    end

    #
    # ABSTRACT - OPTIONAL
    #
    # This is called after run() has finished executing,
    #
    def clean_up( )
    end
    
    #
    # ABSTRACT - REQUIRED
    #
    # Provides information about the module.
    # Don't take this lightly and don't ommit any of the info.
    #
    def self.info
        {
            'Name'           => 'Base module abstract class',
            'Description'    => %q{Provides an abstract the modules should implement.},
            #
            # Arachni needs to know what elements the module plans to audit
            # before invoking it. If a page doesn't have any of those elements
            # there's no point in instantiating the module.
            #
            # If you want the module to run no-matter what leave the array
            # empty or don't define it at all.
            #
#            'Elements'       => ['links', 'forms', 'cookies'],
            'Elements'       => [],
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
            'References'     => {
            },
            'Targets'        => { 'Generic' => 'all' },
            'Vulnerability'   => {
                'Description' => %q{},
                'CWE'         => '',
                #
                # Severity can be:
                #
                # Vulnerability::Severity::HIGH
                # Vulnerability::Severity::MEDIUM
                # Vulnerability::Severity::LOW
                # Vulnerability::Severity::INFORMATIONAL
                #
                'Severity'    => '',
                'CVSSV2'       => '',
                'Remedy_Guidance'    => '',
                'Remedy_Code' => '',
            }
        }
    end
    
    #
    # ABSTRACT - OPTIONAL
    #
    # In case you depend on other modules you can return an array
    # of their names (not their class names, the module names as they
    # appear by the "-l" CLI argument) and they will be loaded for you.
    #
    # This is also great for creating audit/discovery/whatever profiles.
    #
    def self.deps
        # example:
        # ['eval', 'sqli']
        []
    end
    
    #####
    #
    # *DO NOT* override the following methods.
    #
    #####

    #
    # TODO: Put all helper auditor methods in an auditor class
    # and delegate
    #

    #
    # Audits HTTP request headers injecting the injection_str as values
    # and then matching the response body against the id_regex.
    #
    # If the id argument has been provided the matched data of the
    # id_regex will be =='ed against it.
    #
    # @param    [String]     injection_str
    # @param    [String]     id_regex     regular expression string
    # @param    [String]     id  string to double check the id_regex
    #                            matched data
    #
    # @param    [Block]     block to be executed right after the
    #                            request has been made.
    #                            It will be passed the currently audited
    #                            variable and the response.
    #
    # @param    [Array<Hash<String, String>>]    the positive results of
    #                                                the audit, if no block
    #                                                has been given
    #
    def audit_headers( injection_str, id_regex = nil, id = nil, &block )

        results = []
        
        # iterate through header fields and audit each one
        inject_each_var( get_request_headers( true ), injection_str ).each {
            |vars|

            # tell the user what we're doing
            print_status( self.class.info['Name']  + 
                " is auditing:\theader field '" +
                vars['altered'] + "' of " + @page.url )
            
            # audit the url vars
            res = @http.header( @page.url, vars['hash'] )

            # something might have gone bad,
            # make sure it doesn't ruin the rest of the show...
            if !res then next end
            
            # call the passed block
            if block_given?
                block.call( vars['altered'], res )
                return
            end
            
            if !res.body then next end
            
            # get matches
            result = get_matches( Vulnerability::Element::HEADER,
                vars['altered'], res, injection_str, id_regex, id )
                                   
            # and append them to the results array
            results << result if result
        }

        results
    end
        
    #
    # Audits links injecting the injection_str as value for the
    # variables and then matching the response body against the id_regex.
    #
    # If the id argument has been provided the matched data of the
    # id_regex will be =='ed against it.
    #
    # @param    [String]     injection_str
    # @param    [String]     id_regex     regular expression string
    # @param    [String]     id  string to double check the id_regex
    #                            matched data
    #
    # @param    [Block]     block to be executed right after the
    #                            request has been made.
    #                            It will be passed the currently audited
    #                            variable and the response.
    #
    # @param    [Array<Hash<String, String>>]    the positive results of
    #                                                the audit, if no block
    #                                                has been given
    #
    def audit_links( injection_str, id_regex = nil, id = nil, &block )

        results = []
        
        # iterate through all url vars and audit each one
        inject_each_var( @page.query_vars, injection_str ).each {
            |vars|

            # tell the user what we're doing
            print_status( self.class.info['Name']  + 
                " is auditing:\tlink var '" +
                vars['altered'] + "' of " + @page.url )
            
            # audit the url vars
            res = @http.get( @page.url, vars['hash'] )

            # something might have gone bad,
            # make sure it doesn't ruin the rest of the show...
            if !res then next end
            
            # call the passed block
            if block_given?
                block.call( vars['altered'], res )
                return
            end
            
            if !res.body then next end
            
            # get matches
            result = get_matches( Vulnerability::Element::LINK,
                vars['altered'], res, injection_str, id_regex, id )
                                   
            # and append them to the results array
            results << result if result
        }

        results
    end

    #
    # Audits forms injecting the injection_str as value for the
    # variables and then matching the response body against the id_regex.
    #
    # If the id argument has been provided the matched data of the
    # id_regex will be =='ed against it.
    #
    # @param    [String]     injection_str
    # @param    [String]     id_regex     regular expression string
    # @param    [String]     id  string to double check the id_regex
    #                                matched data
    #
    # @param    [Block]     block to be executed right after the
    #                            request has been made.
    #                            It will be passed the currently audited
    #                            variable and the response.
    #
    # @param    [Array<Hash<String, String>>]    the positive results of
    #                                                the audit, if no block
    #                                                has been given
    #
    def audit_forms( injection_str, id_regex = nil, id = nil, &block )
        
        results = []
        
        # iterate through each form
        get_forms_simple.each_with_index {
            |form, i|
            # if we don't have any auditable elements just return
            if !form then return results end
            
            # iterate through each auditable element
            inject_each_var( form, injection_str ).each {
                |input|

                # inform the user what we're auditing
                print_status( self.class.info['Name']  + 
                    " is auditing:\tform input '" +
                    input['altered'] + "' with action " +
                    get_forms()[i]['attrs']['action'] )

                if( get_forms()[i]['attrs']['method'] != 'get' )
                        res =
                            @http.post( get_forms()[i]['attrs']['action'],
                                input['hash'] )
                else
                    # the form's server-side handler may not sanitize
                    # GET input so give it a shot
                    res =
                        @http.get( get_forms()[i]['attrs']['action'],
                            input['hash'] )
                end
                
                # make sure that we have a response before continuing
                if !res then next end
                
                # call the block, if there's one
                if block_given?
                    block.call( input['altered'], res )
                    return
                end

                if !res.body then next end
            
                # get matches
                result = get_matches( Vulnerability::Element::LINK,
                    input['altered'], res, injection_str, id_regex, id )
                
#                result = result.merge get_matches( 'forms', input['altered'],
#                                get_res, injection_str, id_regex, id )
                                                
                # and append them
                results << result if result
            }
        }
        results
    end

    #
    # Audits cookies injecting the injection_str as value for the
    # cookies and then matching the response body against the id_regex.
    #
    # If the id argument has been provided the matched data of the
    # id_regex will be =='ed against it.
    #
    # @param    [String]     injection_str
    # @param    [String]     id_regex     regular expression string
    # @param    [String]     id  string to double check the id_regex
    #                                matched data
    #
    # @param    [Block]     block to be executed right after the
    #                            request has been made.
    #                            It will be passed the currently audited
    #                            variable and the response.
    #
    # @param    [Array<Hash<String, String>>]    the positive results of
    #                                                the audit, if no block
    #                                                has been given
    #
    def audit_cookies( injection_str, id_regex = nil, id = nil, &block )
        
        results = []
        
        # iterate through each cookie    
        inject_each_var( get_cookies_simple, injection_str ).each {
            |cookie|

            # tell the user what we're auditing
            print_status( self.class.info['Name']  + 
                " is auditing:\tcookie '" +
                cookie['altered'] + "' of " + @page.url )

            # make a get request with our cookies
            res = @http.cookie( @page.url, cookie['hash'], nil )

            # check for a response
            if !res then next end
            
            if block_given?
                block.call( cookie['altered'], res )
                return
            end
            
            if !res.body then next end
                
            # get possible matches
            result = get_matches( Vulnerability::Element::COOKIE,
                cookie['altered'], res, injection_str, id_regex, id )
            # and append them
            results << result if result
        }

        results
    end

    #
    # Returns extended form information from {Page#elements}
    #
    # @see Page#get_forms
    #
    # @return    [Aray]    forms with attributes, values, etc
    #
    def get_forms
        @page.get_forms( )
    end

    #
    #
    # Returns extended link information from {Page#elements}
    #
    # @see Page#get_links
    #
    # @return    [Aray]    link with attributes, variables, etc
    #
    def get_links
        @page.get_links( )
    end

    #
    # Returns an array of forms from {#get_forms} with the auditable
    # inputs as a name=>value hash
    #
    # @return    [Array]
    #
    def get_forms_simple
        forms = []
        get_forms( ).each_with_index {
            |form, i|
            forms[i] = Hash.new
            
            form['auditable'].each {
                |item|
                
                if( !item['name'] ) then next end
                forms[i][item['name']] = item['value']
            } rescue forms
            
        }
        forms
    end

    #
    # Returns links from {#get_links} as a name=>value hash with href as key
    #
    # @return    [Hash]
    #
    def get_links_simple
        links = Hash.new
        get_links( ).each_with_index {
            |link, i|
            
            if( !link['vars'] || link['vars'].size == 0 ) then next end
                
            links[link['href']] = Hash.new
            link['vars'].each_pair {
                |name, value|
                
                if( !name || !link['href'] ) then next end
                    
                links[link['href']][name] = value
            }
            
        }
        links
    end
    
    #
    # Returns extended cookie information from {Page#elements}
    #
    # @see Page#get_cookies
    #
    # @return    [Array]    the cookie attributes, values, etc
    #
    def get_cookies
        @page.get_cookies( )
    end

    #
    # Returns cookies from {#get_cookies} as a name=>value hash
    #
    # @return    [Hash]    the cookie attributes, values, etc
    #
    def get_cookies_simple
        cookies = Hash.new( )
        get_cookies( ).each {
            |cookie|
            cookies[cookie['name']] = cookie['value']
        }
        cookies
    end
    
    def get_matches( where, var, res, injection_str, id_regex, id )
        
        # fairly obscure condition...pardon me...
        if ( id && res.body.scan( id_regex )[0] == id ) ||
           ( !id && res.body.scan( id_regex )[0].size > 0 )
        
            print_ok( self.class.info['Name'] + " in: #{where} var #{var}" +
            '::' + @page.url )
            
            print_verbose( "Injected str:\t" + injection_str )    
            print_verbose( "ID str:\t\t" + id )
            print_verbose( "Matched regex:\t" + id_regex.to_s )
            print_verbose( '---------' ) if only_positives?
    
            return {
                'var'          => var,
                'url'          => @page.url,
                'injected'     => injection_str,
                'id'           => id,
                'regexp'       => id_regex.to_s,
                'regexp_match' => res.body.scan( id_regex ),
                'response'     => res.body,
                'elem'         => where,
                'headers'      => {
                    'request'    => get_request_headers( ),
                    'response'   => get_response_headers( res ),    
                }
            }
        end
    end
    
    #
    # Returns a hash of request headers.
    #
    # If 'merge' is set to 'true' cookies will be skipped.<br/>
    # If you need to audit cookies use {#get_cookies} or {#audit_cookies}.
    #
    # @see Page#request_headers
    #
    # @param    [Bool]    merge   merge with auditable ({Page#request_headers}) headers?
    #
    # @return    [Hash]
    #
    def get_request_headers( merge = false )
        
        if( merge == true && @page.request_headers )
            begin
            ( headers = ( @http.init_headers ).
                merge( @page.request_headers ) ).delete( 'cookie' )
            rescue
                headers = {}
            end
            return headers 
        end
        
       return @http.init_headers
    end
    
    #
    # Returns the headers from a Net::HTTP response as a hash
    #
    # @param  [Net::HTTPResponse]  res
    #
    # @return    [Hash] 
    #
    def get_response_headers( res )
        
        header = Hash.new
        res.each_capitalized {
            |key|
            header[key] = res.get_fields( key ).join( "\n" )
        }
        
        header
    end
    
    #
    # Gets module data files from 'modules/[modname]/[filename]'
    #
    # @param    [String]    filename filename, without the path    
    # @param    [Block]     the block to be passed each line as it's read
    #
    def get_data_file( filename, &block )
        
        # the path of the module that called us
        mod_path = block.source_location[0]
        
        # the name of the module that called us
        mod_name = File.basename( mod_path, ".rb")
        
        # the path to the module's data file directory
        path    = File.expand_path( File.dirname( mod_path ) ) +
            '/' + mod_name + '/'
                
        file = File.open( path + '/' + filename ).each {
            |line|
            yield line.strip
        }
        
        file.close
             
    end
    
    #
    # Iterates through a hash setting each value to to_inj
    # and returns an array of new hashes
    #
    # @param    [Hash]    hash    name=>value pairs
    # @param    [String]    to_inj    the string to inject
    #
    # @return    [Array]
    #
    def inject_each_var( hash, to_inj )
        
        var_combo = []
        
        if( !hash || hash.size == 0 ) then return [] end
            
        hash.keys.each {
            |k|
            
            if( !hash[k] ) then hash[k] = '' end
            
            var_combo << { 
                'altered' => k,
                'hash'    => hash.merge( { k => to_inj } )
            }
        }
        
#        filled = Hash.new
#        filled['hash'] = hash
#            
#        filled['hash'].keys.each {
#            |k|
#            
#            if( !filled[k] ) then filled[k] = '' end
#            
#            filled = { 
#                'altered' => '__all',
#                'hash'    => filled['hash'].merge( { k => to_inj } )
#            }
#        }
        
        var_combo
    end


end
end
end
