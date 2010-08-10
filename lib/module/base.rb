=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require Arachni::Options.instance.dir['lib'] + 'module/trainer'
require Arachni::Options.instance.dir['lib'] + 'module/auditor'

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

    include Auditor
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
    
       
end
end
end
