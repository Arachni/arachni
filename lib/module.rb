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
            
            print_status( self.class.info['Name']  + ' is auditing: ' +
                var + ' var in ' + page_data['url']['href'] )
                
            res = @http.get( page_data['url']['href'],
                { var => injection_str } )

            if block_given?
                block.call( var, res )
                return
            end
                                    
            if ( id && res.body.scan( id_regex )[0] == id ) ||
               ( !id && res.body.scan( id_regex )[0].size > 0 )

                results << { var => page_data['url']['href'] }

                print_ok( self.class.info['Name'] + " in: var #{var}" + '::' +
                page_data['url']['href'] )

            end
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
            
        get_forms.each {
            |form|
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
                
                input['value'] = injection_str

                if !input['name']
                    #        input['name'] = '<n/a>'
                    next
                end

                print_status( self.class.info['Name']  + ' is auditing: ' + input['name'] + ' input for ' +
                    form['attrs']['action'] )

                res = @http.post( form['attrs']['action'],
                    { input['name'] => injection_str } )

                if block_given?
                    block.call( input['name'], res )
                    return
                end
                                
                if ( id && res.body.scan( id_regex )[0] == id ) ||
                   ( !id && res.body.scan( id_regex )[0].size > 0 )

                    results << { input['name'] => page_data['url']['href'] }

                    print_ok( self.class.info['Name'] + " in: form input: " +
                    input['name'] + ':: action: ' + form['attrs']['action'] )
                end
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
            
            cookie['value'] = injection_str

            print_status( self.class.info['Name']  + ' is auditing: ' +
                cookie['name'] + ' cookie in ' +
                page_data['url']['href'] )

            res = @http.cookie( page_data['url']['href'], [cookie], nil )

            if block_given?
                block.call( cookie['name'], res )
                return
            end
            
            if ( id && res.body.scan( id_regex )[0] == id ) ||
               ( !id && res.body.scan( id_regex )[0].size > 0 )

                results << { cookie['name'] => page_data['url']['href'] }

                print_ok( self.class.info['Name'] + " in: cookie #{cookie['name']}" +
                '::' + page_data['url']['href'] )
            end
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

end
end
