=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Automated login plugin using a custom login script.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Plugins::LoginScript < Arachni::Plugin::Base

    STATUSES  = {
        success:         'Login was successful.',
        failure:         'The script was executed successfully, but the login check failed.',
        error:           'A runtime error was encountered while executing the login script.',
        missing_browser: 'A browser is required for this operation but is not available.',
        missing_check:   'No session check was provided, either via interface options or the script.'
    }

    def prepare
        script    = IO.read( @options[:script] )
        @script   = proc do |browser|
            if javascript?
                browser.goto @framework.options.url
                browser.execute_script script
            else
                eval script
            end
        end
    end

    def run
        if javascript? && !session.has_browser?
            set_status :missing_browser, :error
            return
        end

        framework_pause
        print_info 'System paused.'

        session.record_login_sequence do |browser|
            print_info 'Running the script.'
            @script.call browser ? browser.watir : nil

            # JS run async so we need to wait for the page to settle after
            # execution.
            session.browser.wait_till_ready if javascript?

            print_info 'Execution completed.'
        end

        begin
            session.login( true )
        rescue => e
            set_status :error
            return
        end

        if !session.logged_in?
            set_status :failure, :error
            return
        end

        cookies = http.cookies.inject({}){ |h, c| h.merge!( c.simple ) }

        set_status :success, :ok, { 'cookies' => cookies }

        print_info 'Cookies set to:'
        cookies.each do |name, val|
            print_info "    * #{name.inspect} = #{val.inspect}"
        end

    rescue Arachni::Session::Error::NoLoginCheck
        set_status :missing_check, :error
    rescue => e
        set_status :error
        print_exception e
    end

    def clean_up
        if @failed
            print_info 'Aborting the scan.'
            framework_abort
            return
        end

        framework_resume
    end

    def javascript?
        @options[:script].split( '.' ).last == 'js'
    end

    def set_status( status, type = nil, extra = {} )
        type ||= status

        register_results(
            {
                'status'  => status.to_s,
                'message' => STATUSES[status]
            }.merge( extra )
        )

        @failed = true if type == :error
        send "print_#{type}", STATUSES[status]
    end

    def self.info
        {
            name:        'Login script',
            description: %q{
Loads and sets an external script as the system's login sequence, to be executed
prior to the scan and whenever a log-out is detected.

The script needn't necessarily perform an actual login operation. If another
process is used to manage sessions, the script can be used to communicate with
that process and, for example, load and set cookies from a shared cookie-jar.

# Ruby

## With browser (slow)

If a [browser](http://watirwebdriver.com/) is available, it will be exposed to
the script via the `browser` variable. Otherwise, that variable will have a
value of `nil`.

    browser.goto 'http://testfire.net/bank/login.aspx'

    form = browser.form( id: 'login' )
    form.text_field( name: 'uid' ).set 'jsmith'
    form.text_field( name: 'passw' ).set 'Demo1234'

    form.submit

    # You can also configure the session check from the script, dynamically,
    # if you don't want to set static options via the user interface.
    framework.options.session.check_url     = browser.url
    framework.options.session.check_pattern = /Sign Off|MY ACCOUNT/

## Without browser (fast)

If a real browser environment is not required for the login operation, then
using the system-wide HTTP interface is preferable, as it will be much faster
and consume much less resources.

    response = http.post( 'http://testfire.net/bank/login.aspx',
        parameters:     {
            'uid'   => 'jsmith',
            'passw' => 'Demo1234'
        },
        mode:           :sync,
        update_cookies: true
    )

    framework.options.session.check_url     = to_absolute( response.headers.location, response.url )
    framework.options.session.check_pattern = /Sign Off|MY ACCOUNT/

## From cookie-jar

If an external process is used to manage sessions, you can keep Arachni in sync
by loading cookies from a shared Netscape-style cookie-jar file.

    http.cookie_jar.load 'cookies.txt'

# Javascript

When the given script has a `.js` file extension, it will be loaded and executed
in the browser, within the page of the target URL.

    document.getElementById( 'uid' ).value   = 'jsmith';
    document.getElementById( 'passw' ).value = 'Demo1234';

    document.getElementById( 'login' ).submit();

},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.2.1',
            options:     [
                Options::Path.new( :script,
                    required:    true,
                    description: 'Script that includes the login sequence.'
                ),
            ],
            priority:    0 # run before any other plugin
        }
    end

end
