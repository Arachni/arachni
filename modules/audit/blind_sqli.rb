=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules

#
# Blind SQL injection audit module
#
# It uses reverse-diff analysis of HTML code in order to determine successful
# blind SQL injections.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2.2
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://capec.mitre.org/data/definitions/7.html
# @see http://www.owasp.org/index.php/Blind_SQL_Injection
#
class BlindSQLInjection < Arachni::Module::Base

    def initialize( page )
        super( page )

        # initialize the results array
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
           # we need 2 requests thus we change the second one a little bit to
           # fool the Auditor's redundancy filter
           '\'"``'
         ]

        # %q% will be replaced by a character in @__quotes
        @__injection = '%q% and %q%1'

        @__opts = {
            :format      => [ Format::APPEND ],
            # we need to do our own redundancy checks
            :redundant   => true,
            # sadly, we need to disable asynchronous requests
            # otherwise the code would get *really* ugly
            :async       => false
        }

        # used for redundancy checks
        @@__audited ||= []

    end

    def run( )

        return if( __audited? )

        if( !@page.query_vars || @page.query_vars.empty? )
            print_status( 'Nothing to audit on current page, skipping...' )
            return
        end

        # get the link object that fits the URL of the page
        # this will be the one to audit
        @page.links.each {
            |link|
            @__candidate = link if link.action == @page.url
        }

        return if !@__candidate

        # let's get a fresh rendering of the page to assist us with
        # irrelevant dynamic content elimination (banners, ads, etc...)
        opts = {}
        opts[:params] = @page.query_vars
        opts[:async]  = false
        res  = @http.get( @page.url, opts ).response

        # eliminate dynamic content that's context-irrelevant
        # ie. changing with every refresh
        @__content = @page.html.rdiff( res.body )

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

    def clean_up
        @@__audited << __audit_id( )
        @@__audited.uniq!
    end

    def __audit_id
        "#{URI( @page.url).path}::#{@page.query_vars.keys}"
    end

    def __audited?
        @@__audited.include?( __audit_id( ) )
    end

    # Audits page with 'bad' SQL characters and gathers error pages
    def __prep_bad_response( )

        @__html_bad ||= {}

        @__bad_chars.each {
            |str|

            # get injection variations that will hopefully cause an internal/silent
            # SQL error
            @__candidate.injection_sets( str, @__opts ).each {
                |variation|

                # the altered link variable
                altered = variation.keys[0]
                # auditable link object
                link    = variation.values[0]

                print_status( @__candidate.get_status_str( altered ) )

                # register us as the auditor
                link.auditor( self )
                # submit the link and get the response
                res = link.submit( @__opts ).response

                @__html_bad[altered] ||= res.body.clone

                # remove context-irrelevant dynamic content like banners and such
                # from the error page
                @__html_bad[altered] = @__html_bad[altered].rdiff( res.body.clone )
            }
        }

        return @__html_bad
    end

    # Injects SQL code that doesn't affect the flow of execution nor presentation
    def __audit( )

        @__html_good ||= {}

        @__quotes.each {
            |quote|

            # prepare the statement with combinations of quote characters
            str = @__injection.gsub( '%q%', quote )

            # get injection variations that will hopefully not break anything
            @__candidate.injection_sets( str, @__opts ).each {
                |variation|

                # the altered link variable
                altered = variation.keys[0]
                # auditable link object
                link    = variation.values[0]

                # register us as the auditor
                link.auditor( self )

                # submit the link and get the response
                res = link.submit( @__opts ).response

                @__html_good[altered] ||= []

                # save the response for later analysis
                @__html_good[altered] << {
                    'str'  => str,
                    'res'  => res
                }

            }
        }

    end

    # Goes through the responses induced by {#__audit} and {#__check} their code
    def __analyze( )
        @__html_good.keys.each {
            |key|
            @__html_good[key].each {
                |res|
                __check( res['str'], res['res'], key )
            }
        }
    end

    #
    # Compares HTML responses in order to identify successful blind sql injections
    #
    # @param  [String]  str  the string that unveiled the vulnerability
    # @param  [Typhoeus::Response]
    # @param  [String]  var   the vulnerable variable
    #
    def __check( str, res, var )

        # if one of the injections gives the same results as the
        # original page then a blind SQL injection exists
        check = res.body.rdiff( @page.html )

        if( check == @__content && @__html_bad[var] != check &&
            !@http.custom_404?( res ) && res.code == 200 )
            __log_results( var, res, str )
        end

    end

    def self.info
        {
            :name           => 'Blind SQL Injection',
            :description    => %q{It uses rDiff analysis to decide how different inputs affect
                the behavior of the the web pages.
                Using that as a basis it extrapolates about what inputs are vulnerable to blind SQL injection.
                (Note: This module may get confused by certain types of XSS vulnerabilities.
                    If this module returns a positive result you should investigate nonetheless.)},
            :elements       => [
                Vulnerability::Element::LINK
            ],
            :author          => 'zapotek',
            :version         => '0.2.2',
            :references      => {
                'OWASP'      => 'http://www.owasp.org/index.php/Blind_SQL_Injection',
                'MITRE - CAPEC' => 'http://capec.mitre.org/data/definitions/7.html'
            },
            :targets        => { 'Generic' => 'all' },

            :vulnerability   => {
                :name        => %q{Blind SQL Injection},
                :description => %q{SQL code can be injected into the web application
                    even though it may not be obvious due to suppression of error messages.},
                :cwe         => '89',
                :severity    => Vulnerability::Severity::HIGH,
                :cvssv2       => '9.0',
                :remedy_guidance    => %q{Suppression of error messages leads to
                    security through obscurity which is not a good practise.
                    The web application needs to enforce stronger validation
                    on user inputs.},
                :remedy_code => '',
                :metasploitable => 'unix/webapp/arachni_sqlmap'
            }

        }
    end

    private

    def __log_results( var, res, str )

        url = res.effective_url

        # since we bypassed the auditor completely we need to create
        # our own opts hash and pass it to the Vulnerability class.
        #
        # this is only required for Metasploitable vulnerabilities
        opts = {
            :injected_orig => URI( @page.url ).query,
            :combo         => @__candidate.auditable
        }

        @results << Vulnerability.new( {
                :var          => var,
                :url          => url,
                :method       => res.request.method.to_s,
                :opts         => opts,
                :injected     => str,
                :id           => str,
                :regexp       => 'n/a',
                :regexp_match => 'n/a',
                :elem         => Vulnerability::Element::LINK,
                :response     => res.body,
                :headers      => {
                    :request    => res.request.headers,
                    :response   => res.headers,
                }
            }.merge( self.class.info )
        )

        print_ok( "In #{Vulnerability::Element::LINK} var '#{var}' ( #{url} )" )
        #
        # If I un-comment the following, with debugging disabled,
        # something will block for a long time... how weird is that?
        #
        # print_debug( 'Request ID: ' + res.request.id.to_s )
        # print_debug( 'Body: ' + res.body )

        # register our results with the system
        register_results( @results )
    end

end
end
end
