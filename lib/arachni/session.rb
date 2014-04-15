=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

# Session management class.
#
# Handles logins, provided log-out detection, stores and executes login sequences
# and provided general webapp session related helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Session
    include UI::Output
    include Utilities

    personalize_output

    # {Session} error namespace.
    #
    # All {Session} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Arachni::Error

        # Raised when trying to {#login} without proper {#configure configuration}.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class NotConfigured < Error
        end

        # Raised when a login check is required to perform an action but none
        # has been configured.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class NoLoginCheck < Error
        end

        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class FormNotFound < Error
        end
    end

    LOGIN_TRIES      = 5
    LOGIN_RETRY_WAIT = 5

    # @return   [Browser]
    attr_reader :browser

    # @return   [Hash,nil]
    attr_reader :options

    def clean_up
        return if ! @browser
        @browser.shutdown
        @browser = nil
    end

    # @return   [Array<Element::Cookie>]
    #   Session cookies.
    def cookies
        http.cookies.select(&:session?)
    end

    # Tries to find the main session (login/ID) cookie.
    #
    # @param    [Block] block
    #   Block to be passed the cookie.
    #
    # @raise    [Error::NoLoginCheck]
    #   If no login-check has been configured.
    def cookie( &block )
        return block.call( @session_cookie ) if @session_cookie
        fail Error::NoLoginCheck, 'No login-check has been configured.' if !has_login_check?

        cookies.each do |cookie|
            logged_in?( cookies: { cookie.name => '' } ) do |bool|
                next if bool
                block.call( @session_cookie = cookie )
            end
        end
    end

    # @param    [Hash]  options
    # @option   options [String]    :url
    #   URL containing the login form.
    # @option   options [Hash{String=>String}]    :inputs
    #   Hash containing inputs with which to locate and fill-in the form.
    def configure( options )
        @options = options.dup
    end

    # @return   [Bool]
    #   `true` if {#configure configured}, `false` otherwise.
    def configured?
        !!@options
    end

    # Finds a login forms based on supplied location, collection and criteria.
    #
    # @param    [Hash] opts
    # @option opts [Bool] :requires_password
    #   Does the login form include a password field? (Defaults to `true`)
    # @option opts [Array, Regexp] :action
    #   Regexp to match or String to compare against the form action.
    # @option opts [String, Array, Hash, Symbol] :inputs
    #   Inputs that the form must contain.
    # @option opts [Array<Element::Form>] :forms
    #   Collection of forms to look through.
    # @option opts [Page, Array<Page>] :pages
    #   Pages to look through.
    # @option opts [String] :url
    #   URL to fetch and look for forms.
    # @option opts [Bool] :with_browser
    #   Does the login form require a {Browser} environment?
    #
    # @param    [Block] block
    #   If a block and a :url are given, the request will run async and the
    #   block will be called with the result of this method.
    def find_login_form( opts = {}, &block )
        async = block_given?

        requires_password = (opts[:requires_password].nil? ? true : opts[:requires_password])

        find = proc do |cforms|
            cforms.select do |f|
                next if requires_password && !f.requires_password?

                oks = []

                if action = opts[:action]
                    oks << !!(action.is_a?( Regexp ) ? f.action =~ action : f.action == action)
                end

                if inputs = opts[:inputs]
                    oks << f.has_inputs?( inputs )
                end

                oks.count( true ) == oks.size
            end.first
        end

        forms = if opts[:pages]
                    [opts[:pages]].flatten.map { |p| p.forms }.flatten
                elsif opts[:forms]
                    opts[:forms]
                elsif (url = opts[:url])
                    http_opts = {
                        precision: false,
                        http:      {
                            update_cookies:  true,
                            follow_location: true
                        }
                    }

                    if async
                        page_from_url( url, http_opts ) { |p| block.call find.call( p.forms ) }
                    else
                        page_from_url( url, http_opts ).forms
                    end
                end

        find.call( forms || [] ) if !async
    end

    # @return   [Bool]
    #   `true` if there is log-in capability, `false` otherwise.
    def can_login?
        configured? && has_login_check?
    end

    # @return   [Bool, nil]
    #   `true` if logged-in, `false` otherwise, `nil` if there's no log-in
    #   capability.
    def ensure_logged_in
        return if !can_login?
        return true if logged_in?

        print_bad 'The scanner has been logged out.'
        print_info 'Trying to re-login...'

        LOGIN_TRIES.times do |i|
            break if !login.response.timed_out? rescue Error

            print_bad "Login attempt #{i+1} failed, retrying after " <<
                          "#{LOGIN_RETRY_WAIT} seconds..."
            sleep LOGIN_RETRY_WAIT
        end

        if logged_in?
            print_ok 'Logged-in successfully.'
            true
        else
            print_bad 'Could not re-login.'
            false
        end
    end

    # Uses the information provided by {#configure} to login.
    #
    # @return   [Page, nil]
    #   {HTTP::Response} if the login form was submitted successfully,
    #   `nil` if not {#configured?}.
    #
    # @raise    [Error::FormNotFound]
    #   If the form could not be found.
    def login
        fail Error::NotConfigured, 'Please #configure the session first.' if !configured?

        clean_up
        @browser = Browser.new

        form = find_login_form(
            pages:  browser.load( @options[:url] ).to_page,
            inputs: @options[:inputs].keys
        )

        if !form
            fail Error::FormNotFound,
                 "Login form could not be found with: #{@options}"
        end

        form.dom.update @options[:inputs]
        form.dom.auditor = self

        page = nil
        form.dom.submit { |p| page = p }

        http.update_cookies browser.cookies

        page
    end

    # @param    [Block] block
    #   Block to be passed the {#browser}.
    def with_browser( &block )
        block.call browser
    end

    # @param    [Hash]   http_options
    #   HTTP options to use for the check.
    # @param    [Block]  block
    #   If a block has been provided the check will be async and the result will
    #   be passed to it, otherwise the method will return the result.
    #
    # @return   [Bool, nil]
    #   `true` if we're logged-in, `false` otherwise.
    #
    # @raise    [Error::NoLoginCheck]
    #   If no login-check has been configured.
    def logged_in?( http_options = {}, &block )
        fail Error::NoLoginCheck if !has_login_check?

        http_options = http_options.merge(
            mode: block_given? ? :async : :sync
        )

        bool = nil
        http.get( Options.login.check_url, http_options ) do |response|
            bool = !!response.body.match( Options.login.check_pattern )
            block.call( bool ) if block
        end
        bool
    end

    # @return   [Bool]
    #   `true` if a login check exists, `false` otherwise.
    def has_login_check?
        !!(Options.login.check_url && Options.login.check_pattern)
    end

    # @return   [HTTP::Client]
    def http
        HTTP::Client
    end

end
end
