=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end


module Arachni::Parser::Element::Analysis::RDiff

    def self.included( mod )
        # the rdiff attack performs it own redundancy checks so we need this to
        # keep track audited elements
        @@__rdiff_audited ||= Set.new
    end

    RDIFF_OPTIONS =  {
        # append our seeds to the default values
        :format      => [ Arachni::Parser::Element::Mutable::Format::APPEND ],

        # allow duplicate requests
        :redundant   => true,

        # amount of rdiff iterations
        :precision   => 2
    }

    #
    # Performs differential analysis on self and logs an issue should there be one.
    #
    #    opts = {
    #        :precision => 3,
    #        :faults    => [ 'fault injections' ],
    #        :bools     => [ 'boolean injections' ]
    #    }
    #
    #    element.rdiff_analysis( opts )
    #
    # Here's how it goes:
    #   * let default be the default/original response
    #   * let fault   be the response of the fault injection
    #   * let bool    be the response of the boolean injection
    #
    #   a vulnerability is logged if default == bool AND bool.code == 200 AND fault != bool
    #
    # The "bool" response is also checked in order to determine if it's a custom 404, if it is it'll be skipped.
    #
    # If a block has been provided analysis and logging will be delegated to it.
    #
    # @param    [Hash]      opts        available options:
    #                                   * :format -- as seen in {Arachni::Parser::Element::Mutable::OPTIONS}
    #                                   * :precision -- amount of rdiff iterations
    #                                   * :faults -- array of fault injection strings (these are supposed to force erroneous conditions when interpreted)
    #                                   * :bools -- array of boolean injection strings (these are supposed to not alter the webapp behavior when interpreted)
    # @param    [Block]     &block      block to be used for custom analysis of responses; will be passed the following:
    #                                   * injected string
    #                                   * audited element
    #                                   * default response body
    #                                   * boolean response
    #                                   * fault injection response body
    #
    def rdiff_analysis( opts = {}, &block )
        opts = Arachni::Parser::Element::Mutable::OPTIONS.merge( RDIFF_OPTIONS.merge( opts ) )

        # don't continue if there's a missing value
        @auditable.values.each {
            |val|
            return if !val || val.empty?
        }

        return if __rdiff_audited?
        __rdiff_audited!

        responses = {
            :orig => nil,
            :good => {},
            :bad  => {},
            :bad_total  => 0,
            :good_total => 0
        }

        opts[:precision].times {
            # get the default responses
            audit( '', opts ) {
                |res|
                responses[:orig] ||= res.body
                # remove context-irrelevant dynamic content like banners and such
                # from the error page
                responses[:orig] = responses[:orig].rdiff( res.body )
            }
        }

        opts[:precision].times {
            opts[:faults].each {
                |str|

                # get injection variations that will hopefully cause an internal/silent
                # SQL error
                variations = mutations( str, opts )

                responses[:bad_total] =  variations.size

                variations.each {
                    |c_elem|

                    print_status( c_elem.status_string )

                    # submit the link and get the response
                    c_elem.submit( opts ).on_complete {
                        |res|

                        responses[:bad][c_elem.altered] ||= res.body.clone

                        # remove context-irrelevant dynamic content like banners and such
                        # from the error page
                        responses[:bad][c_elem.altered] =
                            responses[:bad][c_elem.altered].rdiff( res.body.clone )
                    }
                }
            }
        }

        opts[:bools].each {
            |str|

            # get injection variations that will not affect the outcome of the query
            variations = mutations( str, opts )

            responses[:good_total] =  variations.size

            variations.each {
                |c_elem|

                print_status( c_elem.status_string )

                # submit the link and get the response
                c_elem.submit( opts ).on_complete {
                    |res|

                    responses[:good][c_elem.altered] ||= []

                    # save the response for later analysis
                    responses[:good][c_elem.altered] << {
                        'str'  => str,
                        'res'  => res,
                        'elem' => c_elem
                    }
                }
            }
        }

        # when this runs the 'responses' hash will have been populated
        http.after_run {

            responses[:good].keys.each {
                |key|

                responses[:good][key].each {
                    |res|

                    if block
                        exception_jail( false ){
                            block.call( res['str'], res['elem'], responses[:orig], res['res'], responses[:bad][key] )
                        }
                    elsif( responses[:orig] == res['res'].body &&
                        responses[:bad][key] != res['res'].body &&
                        res['res'].code == 200 )

                        http.custom_404?( res['res'] ) {
                            |bool|
                            next if bool

                            url = res['res'].effective_url

                            # since we bypassed the auditor completely we need to create
                            # our own opts hash and pass it to the Vulnerability class.
                            #
                            # this is only required for Metasploitable vulnerabilities
                            opts = {
                                :injected_orig => res['str'],
                                :combo         => res['elem'].auditable
                            }

                            @auditor.log_issue(
                                :var          => key,
                                :url          => url,
                                :method       => res['res'].request.method.to_s,
                                :opts         => opts,
                                :injected     => res['str'],
                                :id           => res['str'],
                                :regexp       => 'n/a',
                                :regexp_match => 'n/a',
                                :elem         => res['elem'].type,
                                :response     => res['res'].body,
                                # :verification => true,
                                :headers      => {
                                    :request    => res['res'].request.headers,
                                    :response   => res['res'].headers,
                                }
                            )

                            @auditor.print_ok( "In #{res['elem'].type} var '#{key}' ( #{url} )" )
                        }
                    end

                }
            }
        }
    end

    def __rdiff_audited!
        @@__rdiff_audited << __rdiff_audit_id
    end

    def __rdiff_audited?
        @@__rdiff_audited.include?( __rdiff_audit_id )
    end

    def __rdiff_audit_id
        @action + @auditable.keys.to_s
    end

end
