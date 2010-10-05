=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules
module Audit

#
# Blind SQL injection audit module
# 
# It uses a SQL timing attacks.<br/>
# This is going to be greatly improved in the future<br/>
# to support other DBs as well. 
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://capec.mitre.org/data/definitions/7.html
# @see http://www.owasp.org/index.php/Blind_SQL_Injection
#
class BlindSQLInjection < Arachni::Module::Base

    # register us with the system
    include Arachni::Module::Registrar

    def initialize( page )
        super( page )

        # initialize the results hash
        @results = []
    end

    def prepare( )
        
        # possible quote characters used in SQL statements
        @__quotes = [
            '\'',
            '"',
            ''
        ]

        # this will cause a silent error if there's a blind SQL injection
        @__bad_chars =[
           '\'"`',
           '\'"`'
         ]

        
        # %q% will be replaced by a character in @__quotes
        @__injection = '%q% and %q%1'
        
        @__opts = {
            :format      => [ Format::APPEND ],
            # we don't want the Auditor to make any redundancy checks
            # since we depend on redundant requests to eliminate
            # context irrelevant content
            # :redundant   => true,
            # sadly, we need to disable asynchronous requests
            # otherwise the code would get *really* ugly
            :async       => false
        }
        
    end
    
    def run( )
        
        if( @page.query_vars.empty? )
            print_status( 'Nothing to audit on current page, skipping...' )
            return
        end
        
        # let's get a fresh rendering of the page to assist us with
        # irrelevant dynamic content elimination (banners, ads, etc...)
        res  = @http.get( @page.url, @page.query_vars, nil, nil, true ).response

        # eliminate dynamic content that's context irrelevant
        # ie. changing with every refresh
        @__content = Module::Utilities.rdiff( @page.html, res.body )
        
        # force the webapp to return an error page
        __prep_bad_response( )
        
        # start injecting 'nice' SQL queries 
        __audit( )
        
        # analyze the HTML code of the responses in order to determine
        # which injections were succesfull
        __analyze( )
        
        # register our results with the framework
        register_results( @results )
    end
    
    # audit with 'bad' injections and gather responses
    def __prep_bad_response( )
        
        @__html_bad ||= {}

        @__bad_chars.each {
            |str|
            
            audit( str, @__opts ) {
                |res, var, opts|
                
                next if !res || !res.body
                @__html_bad[var] ||= res.body.clone
                @__html_bad[var] = Module::Utilities.rdiff( @__html_bad[var], res.body.clone )
            }
        }
        
        return @__html_bad
    end
    
    def __audit( )
        
        @__html_good ||= {}
        
        @__quotes.each {
            |quote|
            
            str = @__injection.gsub( '%q%', quote )
            
            audit( str, @__opts ) {
                |res, var, opts|

                @__html_good[var] ||= []

                @__html_good[var] << {
                    'str'  => str,
                    'res'  => res,
                    'opts' => opts
                }
                
            }
        }

    end
    
    def __analyze( )
        @__html_good.keys.each {
            |key|
            @__html_good[key].each {
                |res|
                __check( res['str'], res['res'], key, res['opts'] )
            }
        }
    end
    
    def __check( str, res, var, opts )
      
        # if one of the injections gives the same results as the
        # original page then a blind SQL injection exists
        check = Module::Utilities.rdiff( res.body, @page.html )

        # ap str
        # ap var
        # ap opts
        
        if( check == @__content && @__html_bad[var] != check )
            __log_results( opts, var, res, str )
        end

    end
    
    def self.info
        {
            :name           => 'BlindSQLInjection',
            :description    => %q{Blind SQL injection audit module},
            :elements       => [
                Vulnerability::Element::LINK
            ],
            :author          => 'zapotek',
            :version         => '0.1',
            :references      => {
                'OWASP'      => 'http://www.owasp.org/index.php/Blind_SQL_Injection',
                'MITRE - CAPEC' => 'http://capec.mitre.org/data/definitions/7.html'
            },
            :targets        => { 'Generic' => 'all' },
                
            :vulnerability   => {
                :name        => %q{Blind SQL Injection},
                :description => %q{SQL code can be injected into the web application.},
                :cwe         => '89',
                :severity    => Vulnerability::Severity::HIGH,
                :cvssv2       => '9.0',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end
    
    private
    
    def __log_results( opts, var, res, str )
      
        url = res.effective_url
        @results << Vulnerability.new( {
                :var          => var,
                :url          => url,
                :injected     => str,
                :id           => str,
                :regexp       => 'n/a',
                :regexp_match => 'n/a',
                :elem         => opts[:element],
                :response     => res.body,
                :headers      => {
                    :request    => res.request.headers,
                    :response   => res.headers,    
                }
            }.merge( self.class.info )
        )

        print_ok( "In #{opts[:element]} var '#{var}' ( #{url} )" )
            
        # register our results with the system
        register_results( @results )
    end

end
end
end
end
