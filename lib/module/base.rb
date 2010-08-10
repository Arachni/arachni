=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require Arachni::Options.instance.dir['lib'] + 'module/trainer'

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

    include Trainer
    
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
    
    class << self 
        attr_reader :audited
    end

    #
    # Initializes the module attributes, HTTP client and {Trainer}
    #
    # @see Trainer
    # @see HTTP
    #
    # @param  [Page]  page
    #
    def initialize( page )
        
        @page = page
        @http = Arachni::Module::HTTP.new( @page.url )
        
        #
        # This is a callback.
        # The block will be called for every HTTP response
        # we get during the audit.
        #
        # It's used to train Arachni.
        #
        @http.add_trainer{ |res, url| train( res, url ) }
        
        begin
            @@audited.is_a?( Array )
        rescue
            @@audited = []
        end
        
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
            # before invoking it.
            # If a page doesn't have any of those elements
            # there's no point in instantiating the module.
            #
            # If you want the module to run no-matter what leave the array
            # empty.
            #
            # 'Elements'       => [
            #     Vulnerability::Element::FORM,
            #     Vulnerability::Element::LINK,
            #     Vulnerability::Element::COOKIE,
            #     Vulnerability::Element::HEADER
            # ],
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
    #                            variable, the response and the url.
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

            audit_id = "#{self.class.info['Name']}:" +
                "#{@page.url}:#{Vulnerability::Element::HEADER}:" +
                "#{vars['altered'].to_s}=#{vars['hash'].to_s}"
            
            next if @@audited.include?( audit_id )

            # tell the user what we're doing
            print_status( self.class.info['Name']  + 
                " is auditing:\theader field '" +
                vars['altered'] + "' of " + @page.url )
            
            # audit the url vars
            res = @http.header( @page.url, vars['hash'] )
            @@audited << audit_id

            # something might have gone bad,
            # make sure it doesn't ruin the rest of the show...
            if !res then next end
            
            # call the passed block
            if block_given?
                block.call( @page.url, res, vars['altered'] )
                next
            end
            
            if !res.body then next end
            
            # get matches
            result = get_matches( Vulnerability::Element::HEADER,
                vars['altered'], res, injection_str, id_regex, id, @page.url )
                                   
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
    #                            variable, the response and the url.
    #
    # @param    [Array<Hash<String, String>>]    the positive results of
    #                                                the audit, if no block
    #                                                has been given
    #
    def audit_links( injection_str, id_regex = nil, id = nil, &block )

        results = []
        
        get_links_simple.each_pair {
            |url, link_vars|
            
            # if we don't have any auditable elements just return
            if !link_vars then return results end

            # iterate through all url vars and audit each one
            inject_each_var( link_vars, injection_str ).each {
                |vars|
    
                audit_id = "#{self.class.info['Name']}:" +
                    "#{url}:#{Vulnerability::Element::LINK}:" +
                    "#{vars['altered'].to_s}=#{vars['hash'].to_s}"
                
                next if @@audited.include?( audit_id )

                # tell the user what we're doing
                print_status( self.class.info['Name']  + 
                    " is auditing:\tlink var '" +
                    vars['altered'] + "' of " + url )
                
                # audit the url vars
                res = @http.get( url, vars['hash'] )

                @@audited << audit_id
                
                # something might have gone bad,
                # make sure it doesn't ruin the rest of the show...
                if !res then next end
                
                # call the passed block
                if block_given?
                    block.call( url, res, vars['altered'] )
                    next
                end
                
                if !res.body then next end
                
                # get matches
                result = get_matches( Vulnerability::Element::LINK,
                    vars['altered'], res, injection_str, id_regex, id, url )
                
                # and append them to the results array
                results << result if result
            }
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
    #                            variable, the response and the url.
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
            
            url = get_forms()[i]['attrs']['action']
            # iterate through each auditable element
            inject_each_var( form, injection_str ).each {
                |input|

                audit_id = "#{self.class.info['Name']}:" +
                    "#{url}:" +
                    "#{Vulnerability::Element::FORM}:" + 
                    "#{input['altered'].to_s}=#{input['hash'].to_s}"
                    
                next if @@audited.include?( audit_id )

                # inform the user what we're auditing
                print_status( self.class.info['Name']  + 
                    " is auditing:\tform input '" +
                    input['altered'] + "' with action " + url )

                if( get_forms()[i]['attrs']['method'] != 'get' )
                        res =
                            @http.post( url, input['hash'] )
                else
                    res =
                        @http.get( url, input['hash'] )
                end
                
                @@audited << audit_id
                
                # make sure that we have a response before continuing
                if !res then next end
                
                # call the block, if there's one
                if block_given?
                    block.call( url, res, input['altered'] )
                    next
                end

                if !res.body then next end
            
                # get matches
                result = get_matches( Vulnerability::Element::FORM,
                    input['altered'], res, injection_str, id_regex, id, url )
                
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
    #                            variable, the response and the url.
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

            audit_id = "#{self.class.info['Name']}:" +
                "#{@page.url}:#{Vulnerability::Element::COOKIE}:" +
                "#{cookie['altered'].to_s}=#{cookie['hash'].to_s}"
            
            next if @@audited.include?( audit_id )

            # tell the user what we're auditing
            print_status( self.class.info['Name']  + 
                " is auditing:\tcookie '" +
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
            
            if !res.body then next end
                
            # get possible matches
            result = get_matches( Vulnerability::Element::COOKIE,
                cookie['altered'], res, injection_str, id_regex, id, @page.url )
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
    def get_cookies_simple( incookies = nil )
        cookies = Hash.new( )
        
        incookies = get_cookies( ) if !incookies
        
        incookies.each {
            |cookie|
            cookies[cookie['name']] = cookie['value']
        }
        
        if( Options.instance.audit_cookie_jar )
            return @page.cookiejar.merge( cookies )
        else
            return cookies
        end
    end
    
    def get_matches( where, var, res, injection_str, id_regex, id, url )
        
        # fairly obscure condition...pardon me...
        if ( id && res.body.scan( id_regex )[0] == id ) ||
           ( !id && res.body.scan( id_regex )[0].size > 0 )
        
            print_ok( self.class.info['Name'] + " in: #{where} var #{var}" +
            '::' + url )
            
            print_verbose( "Injected str:\t" + injection_str )    
            print_verbose( "ID str:\t\t" + id )
            print_verbose( "Matched regex:\t" + id_regex.to_s )
            print_verbose( '---------' ) if only_positives?
    
            return {
                'var'          => var,
                'url'          => url,
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
        
        # this is the original hash, in case the default values
        # are valid and present us with new attack vectors
        as_is = Hash.new( )
        as_is['altered'] = '__orig'
        as_is['hash']    = hash.clone
            
        as_is['hash'].keys.each {
            |k|
            if( !as_is['hash'][k] ) then as_is['hash'][k] = '' end
        }
        var_combo << as_is
        
        # these are audit inputs, if a value is empty or null
        # we put a sample e-mail address in its place
        hash.keys.each {
            |k|
            
            hash.keys.each{
                |key|
                hash[key] = 'test@domain.com' if !hash[key] || hash[key].empty?
            }
            
            
            var_combo << { 
                'altered' => k,
                'hash'    => hash.merge( { k => to_inj } )
            }
        }
#         ap var_combo
        var_combo
    end
       
end
end
end
