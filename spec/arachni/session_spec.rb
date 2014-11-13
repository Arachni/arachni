require 'spec_helper'

describe Arachni::Session do

    before( :all ) do
        @url  = web_server_url_for( :session )
        @opts = Arachni::Options.instance
    end

    before(:each) do
        @opts.url = @url
    end
    after( :each ) do
        @session.clean_up if @session
        @opts.reset
        Arachni::HTTP::Client.reset
        Arachni::Data.session.clear
    end

    subject { @session = Arachni::Session.new }
    let(:configured) do
        subject.configure(
            url:    "#{@url}/login",
            inputs: {
                username: 'john',
                password: 'doe'
            }
        )

        @opts.session.check_url     = @url
        @opts.session.check_pattern = 'logged-in user'

        subject
    end

    describe "#{Arachni::OptionGroups::Session}" do
        describe '#has_login_check?' do
            context 'when #check_url and #check_pattern have not been configured' do
                it 'returns false' do
                    subject.has_login_check?.should be_false
                end
            end

            context 'when #check_url and #check_pattern have been configured' do
                it 'returns true' do
                    @opts.session.check_url     = @url
                    @opts.session.check_pattern = 'logged-in user'

                    subject.has_login_check?.should be_true
                end
            end
        end
    end

    describe '#has_browser?' do
        context "when #{Arachni::OptionGroups::Scope}#dom_depth_limit is 0" do
            it 'returns false' do
                Arachni::Options.scope.dom_depth_limit = 0
                subject.has_browser?.should be_false
            end
        end

        context "when not #{Arachni::Browser}.has_executable?" do
            it 'returns false' do
                Arachni::Browser.stub(:has_executable?) { false }
                subject.has_browser?.should be_false
            end
        end
    end

    describe '#configuration' do
        it "returns #{Arachni::Data::Session}#configuration" do
            subject.configuration.object_id.should ==
                Arachni::Data.session.configuration.object_id
        end
    end

    describe '#clean_up' do
        it 'shuts down the #browser' do
            configured.login
            configured.should be_logged_in

            browser = configured.browser
            configured.clean_up
            browser.pid.should be_nil
        end

        it 'clears the #configuration' do
            configured.should be_configured
            configured.clean_up
            configured.should_not be_configured
        end
    end

    describe '#browser' do
        context 'before calling #login' do
            it 'returns nil' do
                configured.browser.should be_nil
            end
        end

        context 'after #login' do
            it "returns an #{Arachni::Browser}" do
                configured.login
                configured.browser.should be_kind_of Arachni::Browser
            end
        end
    end

    describe '#login' do
        context 'when given a login sequence' do
            context 'when a browser is available' do
                it 'passes a browser instance' do
                    b = nil
                    subject.record_login_sequence do |browser|
                        b = browser
                    end

                    subject.login

                    b.should be_kind_of Arachni::Browser
                end

                it 'updates the system cookies from the browser' do
                    subject.record_login_sequence do |browser|
                        browser.goto @url
                        browser.watir.cookies.add 'foo', 'bar'
                    end

                    subject.login

                    Arachni::HTTP::Client.cookies.find { |c| c.name == 'foo' }.should be_true
                end
            end

            context 'when a browser is not available' do
                before { subject.stub(:has_browser?) { false } }

                it 'does not pass a browser instance' do
                    b = true
                    subject.record_login_sequence do |browser|
                        b = browser
                    end

                    subject.login

                    b.should be_nil
                end
            end
        end

        context 'when given login form info' do
            it 'finds and submits the login form with the given credentials' do
                configured.login
                configured.should be_logged_in
            end

            context 'when a browser is not available' do
                before { subject.stub(:has_browser?) { false } }

                it 'uses the framework Page helpers' do
                    configured.should_not be_logged_in
                    configured.login.should be_kind_of Arachni::Page
                    configured.should be_logged_in
                end
            end

            context 'when a browser is available' do
                it 'can handle Javascript forms' do
                    subject.configure(
                        url:    "#{@url}/javascript_login",
                        inputs: {
                            username: 'john',
                            password: 'doe'
                        }
                    )

                    @opts.session.check_url     = @url
                    @opts.session.check_pattern = 'logged-in user'

                    subject.login

                    subject.should be_logged_in
                end

                it 'returns the resulting browser evaluated page' do
                    configured.login.should be_kind_of Arachni::Page

                    transition = configured.login.dom.transitions.first
                    transition.event.should == :load
                    transition.element.should == :page
                    transition.options[:url].should == configured.configuration[:url]

                    transition = configured.login.dom.transitions.last
                    transition.event.should == :submit
                    transition.element.tag_name.should == :form

                    transition.options[:inputs]['username'].should ==
                        configured.configuration[:inputs][:username]

                    transition.options[:inputs]['password'].should ==
                        configured.configuration[:inputs][:password]
                end
            end
        end

        context 'when no configuration has been provided' do
            it "raises #{described_class::Error::NotConfigured}" do
                expect { subject.login }.to raise_error described_class::Error::NotConfigured
            end
        end

        context 'each time' do
            it 'uses a fresh #browser' do
                configured.login
                browser = configured.browser

                configured.login
                configured.browser.object_id.should_not == browser.object_id
                configured.browser.should be_kind_of Arachni::Browser
            end
        end
    end

    describe '#logged_in?' do
        context 'when no login check is available' do
            it "raises #{described_class::Error::NoLoginCheck}" do
                expect { subject.logged_in? }.to raise_error described_class::Error::NoLoginCheck
            end
        end

        context 'when a login check is available' do
            context 'and a valid session is available' do
                it 'returns true' do
                    configured.login
                    configured.should be_logged_in
                end
            end

            context 'and a valid session is not available' do
                it 'returns true' do
                    @opts.session.check_url     = @url
                    @opts.session.check_pattern = 'logged-in user'

                    subject.should_not be_logged_in
                end
            end

            context 'when a block is given' do
                it 'performs the check asynchronously' do
                    configured.login

                    bool = false
                    configured.logged_in? { |b| bool = b }
                    configured.http.run
                    bool.should be_true

                    not_bool = true
                    configured.logged_in?( no_cookie_jar: true ) { |b| not_bool = b }
                    configured.http.run
                    not_bool.should be_false
                end
            end
        end
    end

    describe '#configured?' do
        context 'when login instructions have been provided' do
            it 'returns true' do
                configured.configured?.should be_true
            end
        end

        context 'when login instructions have not been provided' do
            it 'returns false' do
                subject.configured?.should be_false
            end
        end
    end

    describe '#cookies' do
        it 'returns session cookies' do
            subject.http.get @url + '/with_nonce', mode: :sync, update_cookies: true

            subject.cookies.map(&:name).sort.should == %w(rack.session session_cookie).sort
        end
    end

    describe '#cookie' do
        it 'returns the cookie that determines the login status' do
            subject.configure(
                url:    "#{@url}/nonce_login",
                inputs: {
                    username: 'nonce_john',
                    password: 'nonce_doe'
                }
            )

            # lets invalidate the form nonce now
            # (to make sure that it will be refreshed before logging in)
            subject.http.get @url + '/nonce_login', mode: :sync

            subject.configured?.should be_true

            @opts.session.check_url     = @url + '/with_nonce'
            @opts.session.check_pattern = 'logged-in user'

            subject.login

            cookie = nil
            subject.cookie { |c| cookie = c }
            subject.http.run

            cookie.name.should == 'rack.session'

            subject.can_login?.should be_true
        end

        context 'when called without having configured a login check' do
            it 'should raise an exception' do
                expect { subject.cookie }.to raise_error described_class::Error::NoLoginCheck
            end
        end
    end

    describe '#find_login_form' do
        before { @id = "#{@url}/login:form:[\"password\", \"token\", \"username\"]" }
        context 'when passed an array of :pages' do
            it 'should go through its forms and locate the login one' do
                p = Arachni::Page.from_url( @url + '/login' )
                subject.find_login_form( pages: [ p, p ] ).coverage_id.should == @id
            end
        end
        context 'when passed an array of :forms' do
            it 'should go through its forms and locate the login one' do
                p = Arachni::Page.from_url( @url + '/login' )
                subject.find_login_form( forms: p.forms ).coverage_id.should == @id
            end
        end
        context 'when passed a url' do
            it 'store the cookies set by that url' do
                Arachni::HTTP::Client.cookies.should be_empty

                subject.find_login_form( url: @url + '/login' ).coverage_id.should == @id

                Arachni::HTTP::Client.cookies.find do |c|
                    c.name == 'you_need_to' && c.value == 'preserve this'
                end.should be_kind_of Arachni::Cookie
            end

            context 'and called without a block' do
                it 'should operate in blocking mode, go through its forms and locate the login one' do
                    subject.find_login_form( url: @url + '/login' ).coverage_id.should == @id
                end
            end
            context 'and called with a block' do
                it 'should operate in async mode, go through its forms, locate the login one and pass it to the block' do

                    form = nil
                    subject.find_login_form( url: @url + '/login' ) { |f| form = f }
                    subject.http.run

                    form.coverage_id.should == @id
                end
            end
        end
        context 'when passed an array of :inputs' do
            it 'should use them to narrow down the list' do
                subject.find_login_form(
                    url:    @url + '/multiple',
                    inputs: :token
                ).coverage_id.should == @id
            end
        end
        context 'when passed an :action' do
            context Regexp do
                it 'should use it to match against form actions' do
                    subject.find_login_form(
                        url:    @url + '/multiple',
                        action: /login/
                    ).coverage_id.should == @id
                end
            end
            context String do
                it 'should use it to match against form actions' do
                    subject.find_login_form(
                        url:    @url + '/multiple',
                        action: "#{@url}/login"
                    ).coverage_id.should == @id
                end
            end
        end
    end

    describe '#can_login?' do
        context 'when there are no login sequences' do
            it 'returns false' do
                subject.can_login?.should be_false
            end
        end

        context 'when there are login sequences' do
            it 'returns true' do
                configured.can_login?.should be_true
            end
        end
    end

    describe '#ensure_logged_in' do
        context 'when the login is successful' do
            it 'returns true' do
                @opts.session.check_url     = @url + '/with_nonce'
                @opts.session.check_pattern = 'logged-in user'

                subject.configure(
                    url:    "#{@url}/nonce_login",
                    inputs: {
                        username: 'nonce_john',
                        password: 'nonce_doe'
                    }
                )

                subject.logged_in?.should be_false
                subject.ensure_logged_in
                subject.logged_in?.should be_true
            end
        end

        context 'when the login fails' do
            it 'returns false' do
                @opts.session.check_url     = @url + '/with_nonce'
                @opts.session.check_pattern = 'logged-in user'
                subject.configure(
                    url:    "#{@url}/nonce_login",
                    inputs: {
                        username: '1',
                        password: '2'
                    }
                )

                subject.logged_in?.should be_false
                subject.ensure_logged_in
                subject.logged_in?.should be_false
            end
        end

        context 'when the login attempt fails' do
            it 'retries 5 times' do
                @opts.session.check_url     = @url
                @opts.session.check_pattern = 'logged-in user'

                subject.configure(
                    url:    "#{@url}/disappearing_login",
                    inputs: {
                        username: 'john',
                        password: 'doe'
                    }
                )

                subject.logged_in?.should be_false
                subject.ensure_logged_in
                subject.logged_in?.should be_true
            end
        end

        context 'when there is no login capability' do
            it 'returns nil' do
                subject.can_login?.should be_false
                subject.ensure_logged_in.should be_nil
            end
        end
    end

end
