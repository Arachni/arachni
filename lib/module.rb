=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

module Arachni

#
# Arachni::Module class<br/>
# Module base class, to be extended by Arachni::Modules.
#    
# Defines basic structure and provides utilities to modules.
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: 0.1-planning
#
class Module

    #
    # Arachni::HTTP instance for the modules
    #
    # @return [Arachni::HTTP]
    #
    attr_reader :http

    #
    # Hash page data (url, html, headers)
    #
    # @return [Hash<String, String>]
    #
    attr_reader :page_data

    #
    # Structure of the website
    #
    # @return [Hash<String, Hash<Array, Hash>>]
    #
    attr_reader :structure

    #
    # Initializes the module attributes and HTTP client
    #
    # @param  [Hash<String, String>]  page_data
    #
    # @param [Hash<String, Hash<Array, Hash>>]  structure
    #
    def initialize( page_data, structure )
        @http = Arachni::HTTP.new( page_data['url']['href'] )

        @page_data = page_data
        @structure = structure
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
    # it restores the original HTTP session.
    def clean_up( )
    end

    #####
    #
    # *DO NOT* override the following methods.
    #
    #####

    #
    # TODO: Put all helper auditor methods in the auditor class
    # and delegate
    #
    
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
        page_data['url']['vars'].keys.each {
            |var|

            # catch global interrupts and exit...
            if $_interrupted == true
                print_line
                print_info( 'Site audit was interrupted, exiting...' )
                print_line
                print_results( )
                exit 0
            end
            
            # tell the user what we're doing
            print_status( self.class.info['Name']  + ' is auditing: ' +
                var + ' var in ' + page_data['url']['href'] )
            
            # audit the url vars
            res = @http.get( page_data['url']['href'],
                { var => injection_str } )

            # something might have gone bad,
            # make it doesn't ruin the rest of the show...
            if !res || !res.body then next end
            
            # call the passed block
            if block_given?
                block.call( var, res )
                return
            end
            
            # get matches
            result = get_matches( 'links', var, res, id_regex, id )
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
        get_forms.each {
            |form|
            
            # if we don't have any auditable elements just return
            if !form['auditable'] then return results end
            
            # iterate through each auditable element
            form['auditable'].each_with_index {
                |input, i|

                # catch global interrupts and exit...
                if $_interrupted == true
                    print_line
                    print_info( 'Site audit was interrupted, exiting...' )
                    print_line
                    print_results( )
                    exit 0
                end
                
                # inject our own value
                input['value'] = injection_str

                if !input['name']
                    #        input['name'] = '<n/a>'
                    next
                end

                # inform the user what we're auditing
                print_status( self.class.info['Name']  + ' is auditing: ' +
                    input['name'] + ' input for ' +
                    form['attrs']['action'] )

                # post the form
                res = @http.post( form['attrs']['action'],
                    { input['name'] => injection_str } )

                # make sure that we have a response before continuing
                if !res || !res.body then next end
                
                # call the block, if there's one
                if block_given?
                    block.call( input['name'], res )
                    return
                end

                # get matches
                result = get_matches( 'forms', input['name'],
                                res, id_regex, id )
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
        get_cookies.each {
            |cookie|

            # catch global interrupts and exit...
            if $_interrupted == true
                print_line
                print_info( 'Site audit was interrupted, exiting...' )
                print_line
                print_results( )
                exit 0
            end
            
            # inject our own value
            cookie['value'] = injection_str

            # tell the user what we're auditing
            print_status( self.class.info['Name']  + ' is auditing: ' +
                cookie['name'] + ' cookie in ' +
                page_data['url']['href'] )

            # make a get request with our cookies
            res = @http.cookie( page_data['url']['href'], [cookie], nil )

            # check for a response
            if !res || !res.body then next end
            
            if block_given?
                block.call( cookie['name'], res )
                return
            end
            
            # get possible matches
            result = get_matches( 'cookies', cookie['name'],
                        res, id_regex, id )
            # and append them
            results << result if result
        }

        results
    end

    #
    # Returns forms from @structure
    #
    # @return    [Hash]    the form attributes, values, etc
    #
    def get_forms
        @structure['forms']
    end

    #
    # Returns links from @structure
    #
    # @return    [Hash]    the link attributes, variables, etc
    #
    def get_links
        @structure['links']
    end

    #
    # Returns cookies from @structure
    #
    # @return    [Array]    the cookie attributes, values, etc
    #
    def get_cookies
        @structure['cookies']
    end
    
    private

    def get_matches( where, var, res, id_regex, id )
        
        # fairly obscure condition...pardon me...
        if ( id && res.body.scan( id_regex )[0] == id ) ||
           ( !id && res.body.scan( id_regex )[0].size > 0 )
        
            print_ok( self.class.info['Name'] + " in: #{where} var #{var}" +
            '::' + page_data['url']['href'] )
                
            return { var => page_data['url']['href'] }
        end
    end

end
end
