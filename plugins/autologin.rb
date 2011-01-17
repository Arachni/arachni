=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugins

#
# Automated login plugin.
#
# It looks for the login form in the user provided URL,
# merges its input field with the user supplied parameters and sets the cookies
# of the response as framework-wide cookies to be user by the spider later on.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class AutoLogin < Arachni::Plugin::Base

    attr_accessor :http

    #
    # @param    [Arachni::Framework]    framework
    # @param    [Hash]        options    options passed to the plugin
    #
    def initialize( framework, options )
        @framework = framework
        @options   = options

        @framework.pause!
    end

    def prepare
        @parser = Arachni::Parser.new( @framework.opts )
        @params = parse_params

        # we need to declared this in order to pass ourselves
        # as the auditor to the form later in order to submit it.
        @http = @framework.http
    end

    def run( )

        # grab the page containing the login form
        res  = @framework.http.get( @options['url'], :async => false ).response

        # parse the response as a Page object
        page = @parser.run( @options['url'], res.body, res.headers_hash )

        # find the login form
        login_form = nil
        page.forms.each {
            |form|
            login_form = form if login_form?( form )
        }

        if !login_form
            print_error( 'Could not find a form suiting the provided params at: ' +
            @options['url'] )
            return
        end

        name = login_form.raw['attrs']['name'] ? login_form.raw['attrs']['name'] : '<n/a>'
        print_status( "Found log-in form with name: "  + name )

        # merge the input fields of the form with the user supplied parameters
        login_form.auditable.merge!( @params )

        # register us as the auditor
        login_form.auditor( self )
        res = login_form.submit( :async => false ).response

        if !res
            print_error( 'Form submitted but no response was returned.' )
            return
        else
            print_ok( 'Form submitted successfully.' )
        end

    end

    def clean_up
        @framework.resume!
    end

    def login_form?( form )
        avail    = form.auditable.keys
        provided = @params.keys

        provided.each {
            |name|
            return false if !avail.include?( name )
        }

        return true
    end

    def parse_params
        params = {}
        @options['params'].split( '&' ).each {
            |param|
            k, v = param.split( '=', 2 )
            params[k] = v
        }
        return params
    end


    def self.info
        {
            :name           => 'AutoLogin',
            :description    => %q{It looks for the login form in the user provided URL,
                merges its input fields with the user supplied parameters and sets the cookies
                of the response and request as framework-wide cookies to be user by the spider later on.
            },
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                Arachni::OptUrl.new( 'url', [ true, 'The URL that contains the login form.' ] ),
                Arachni::OptString.new( 'params', [ true, 'Form parameters to submit. ( username=user&password=pass )' ] )
            ]
        }
    end

end

end
end
