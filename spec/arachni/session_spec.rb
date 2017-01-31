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
                username:  'john',
                password:  'doe',
                submit_me: 'Login!'
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
                    expect(subject.has_login_check?).to be_falsey
                end
            end

            context 'when #check_url and #check_pattern have been configured' do
                it 'returns true' do
                    @opts.session.check_url     = @url
                    @opts.session.check_pattern = 'logged-in user'

                    expect(subject.has_login_check?).to be_truthy
                end
            end
        end
    end

    describe '#has_browser?' do
        context "when #{Arachni::OptionGroups::Scope}#dom_depth_limit is 0" do
            it 'returns false' do
                Arachni::Options.scope.dom_depth_limit = 0
                expect(subject.has_browser?).to be_falsey
            end
        end

        context "when not #{Arachni::Browser}.has_executable?" do
            it 'returns false' do
                allow(Arachni::Browser).to receive(:has_executable?) { false }
                expect(subject.has_browser?).to be_falsey
            end
        end
    end

    describe '#configuration' do
        it "returns #{Arachni::Data::Session}#configuration" do
            expect(subject.configuration.object_id).to eq(
                Arachni::Data.session.configuration.object_id
            )
        end
    end

    describe '#clean_up' do
        it 'shuts down the #browser' do
            configured.login
            expect(configured).to be_logged_in

            browser = configured.browser
            configured.clean_up
            expect(browser).to be_nil
        end

        it 'clears the #configuration' do
            expect(configured).to be_configured
            configured.clean_up
            expect(configured).not_to be_configured
        end
    end

    describe '#browser' do
        context 'before calling #login' do
            it 'returns nil' do
                expect(configured.browser).to be_nil
            end
        end

        context 'after #login' do
            it 'kills the browser' do
                configured.login
                expect(configured.browser).to be_nil
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

                    expect(b).to be_kind_of Arachni::Browser
                end

                it 'updates the system cookies from the browser' do
                    subject.record_login_sequence do |browser|
                        browser.goto @url
                        browser.watir.cookies.add 'foo', 'bar'
                    end

                    subject.login

                    expect(Arachni::HTTP::Client.cookies.find { |c| c.name == 'foo' }).to be_truthy
                end
            end

            context 'when a browser is not available' do
                before { allow(subject).to receive(:has_browser?) { false } }

                it 'does not pass a browser instance' do
                    b = true
                    subject.record_login_sequence do |browser|
                        b = browser
                    end

                    subject.login

                    expect(b).to be_nil
                end
            end
        end

        context 'when given login form info' do
            it 'finds and submits the login form with the given credentials' do
                configured.login
                expect(configured).to be_logged_in
            end

            context 'when a browser is not available' do
                before { allow(subject).to receive(:has_browser?) { false } }

                it 'uses the framework Page helpers' do
                    expect(configured).not_to be_logged_in
                    expect(configured.login).to be_kind_of Arachni::Page
                    expect(configured).to be_logged_in
                end
            end

            context 'when a browser is available' do
                it 'can handle Javascript forms' do
                    subject.configure(
                        url:    "#{@url}/javascript_login",
                        inputs: {
                            username: 'john',
                            password: 'doe',
                            submit_me: 'Login!'
                        }
                    )

                    @opts.session.check_url     = @url
                    @opts.session.check_pattern = 'logged-in user'

                    subject.login

                    expect(subject).to be_logged_in
                end

                it 'returns the resulting browser evaluated page' do
                    expect(configured.login).to be_kind_of Arachni::Page

                    transitions = configured.login.dom.transitions

                    transition = transitions[0]
                    expect(transition.event).to eq(:load)
                    expect(transition.element).to eq(:page)
                    expect(transition.options[:url]).to eq(configured.configuration[:url])

                    transition = transitions[1]
                    expect(transition.event).to eq(:fill)
                    expect(transition.element.tag_name).to eq(:form)

                    expect(transition.options[:inputs]['username']).to eq(
                        configured.configuration[:inputs][:username]
                    )

                    expect(transition.options[:inputs]['password']).to eq(
                        configured.configuration[:inputs][:password]
                    )

                    expect(transition.options[:inputs]['submit_me']).to eq(
                        configured.configuration[:inputs][:submit_me]
                    )

                    transition = transitions[2]
                    expect(transition.event).to eq(:click)
                    expect(transition.element).to eq(
                        Arachni::Browser::ElementLocator.new(
                            tag_name:   :input,
                            attributes: {
                                "name" => "submit_me",
                                "type" => "submit",
                                "value" => "Login!"
                            }
                        )
                    )
                end

                context 'when a parameter is a submit input' do
                    it 'clicks it' do
                        subject.configure(
                            url:    "#{@url}/login",
                            inputs: {
                                username: 'john',
                                password: 'doe',
                                submit_me: 'Login!'
                            }
                        )

                        @opts.session.check_url     = @url
                        @opts.session.check_pattern = 'logged-in user'

                        subject.login

                        expect(subject).to be_logged_in
                    end
                end

                context 'when no parameters match a submit input' do
                    it 'submits the form' do
                        subject.configure(
                            url:    "#{@url}/without_button",
                            inputs: {
                                username: 'john',
                                password: 'doe'
                            }
                        )

                        @opts.session.check_url     = @url
                        @opts.session.check_pattern = 'logged-in user'

                        subject.login

                        expect(subject).to be_logged_in
                    end
                end
            end
        end

        context 'when no configuration has been provided' do
            it "raises #{described_class::Error::NotConfigured}" do
                expect { subject.login }.to raise_error described_class::Error::NotConfigured
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
            it 'takes into account #check_options' do
                subject.check_options = {
                    cookies: {
                        'custom-cookie' => 'value'
                    }
                }

                Arachni::Options.session.check_url = @url

                expect(subject.http).to receive(:request).with(
                    Arachni::Options.session.check_url,
                    hash_including( subject.check_options )
                )

                configured.logged_in?
            end

            context 'and a valid session is available' do
                it 'returns true' do
                    configured.login
                    expect(configured).to be_logged_in
                end
            end

            context 'and a valid session is not available' do
                it 'returns true' do
                    @opts.session.check_url     = @url
                    @opts.session.check_pattern = 'logged-in user'

                    expect(subject).not_to be_logged_in
                end
            end

            context 'when a block is given' do
                it 'performs the check asynchronously' do
                    configured.login

                    bool = false
                    configured.logged_in? { |b| bool = b }
                    configured.http.run
                    expect(bool).to be_truthy

                    not_bool = true
                    configured.logged_in?( no_cookie_jar: true ) { |b| not_bool = b }
                    configured.http.run
                    expect(not_bool).to be_falsey
                end
            end
        end
    end

    describe '#configured?' do
        context 'when login instructions have been provided' do
            it 'returns true' do
                expect(configured.configured?).to be_truthy
            end
        end

        context 'when login instructions have not been provided' do
            it 'returns false' do
                expect(subject.configured?).to be_falsey
            end
        end
    end

    describe '#cookies' do
        it 'returns session cookies' do
            subject.http.get @url + '/with_nonce', mode: :sync, update_cookies: true

            expect(subject.cookies.map(&:name).sort).to eq(%w(rack.session session_cookie).sort)
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

            expect(subject.configured?).to be_truthy

            @opts.session.check_url     = @url + '/with_nonce'
            @opts.session.check_pattern = 'logged-in user'

            subject.login

            cookie = nil
            subject.cookie { |c| cookie = c }
            subject.http.run

            expect(cookie.name).to eq('rack.session')

            expect(subject.can_login?).to be_truthy
        end

        context 'when called without having configured a login check' do
            it 'should raise an exception' do
                expect { subject.cookie }.to raise_error described_class::Error::NoLoginCheck
            end
        end
    end

    describe '#find_login_form' do
        before { @id = "#{@url}/login:form:[\"password\", \"submit_me\", \"token\", \"username\"]" }
        context 'when passed an array of :pages' do
            it 'should go through its forms and locate the login one' do
                p = Arachni::Page.from_url( @url + '/login' )
                expect(subject.find_login_form( pages: [ p, p ] ).coverage_id).to eq(@id)
            end
        end
        context 'when passed an array of :forms' do
            it 'should go through its forms and locate the login one' do
                p = Arachni::Page.from_url( @url + '/login' )
                expect(subject.find_login_form( forms: p.forms ).coverage_id).to eq(@id)
            end
        end
        context 'when passed a url' do
            it 'store the cookies set by that url' do
                expect(Arachni::HTTP::Client.cookies).to be_empty

                expect(subject.find_login_form( url: @url + '/login' ).coverage_id).to eq(@id)

                expect(Arachni::HTTP::Client.cookies.find do |c|
                    c.name == 'you_need_to' && c.value == 'preserve this'
                end).to be_kind_of Arachni::Cookie
            end

            context 'and called without a block' do
                it 'should operate in blocking mode, go through its forms and locate the login one' do
                    expect(subject.find_login_form( url: @url + '/login' ).coverage_id).to eq(@id)
                end
            end
            context 'and called with a block' do
                it 'should operate in async mode, go through its forms, locate the login one and pass it to the block' do

                    form = nil
                    subject.find_login_form( url: @url + '/login' ) { |f| form = f }
                    subject.http.run

                    expect(form.coverage_id).to eq(@id)
                end
            end
        end
        context 'when passed an array of :inputs' do
            it 'should use them to narrow down the list' do
                expect(subject.find_login_form(
                    url:    @url + '/multiple',
                    inputs: :token
                ).coverage_id).to eq(@id)
            end
        end
        context 'when passed an :action' do
            context 'Regexp' do
                it 'should use it to match against form actions' do
                    expect(subject.find_login_form(
                        url:    @url + '/multiple',
                        action: /login/
                    ).coverage_id).to eq(@id)
                end
            end
            context 'String' do
                it 'should use it to match against form actions' do
                    expect(subject.find_login_form(
                        url:    @url + '/multiple',
                        action: "#{@url}/login"
                    ).coverage_id).to eq(@id)
                end
            end
        end
    end

    describe '#can_login?' do
        context 'when there are no login sequences' do
            it 'returns false' do
                expect(subject.can_login?).to be_falsey
            end
        end

        context 'when there are login sequences' do
            it 'returns true' do
                expect(configured.can_login?).to be_truthy
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

                expect(subject.logged_in?).to be_falsey
                subject.ensure_logged_in
                expect(subject.logged_in?).to be_truthy
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

                expect(subject.logged_in?).to be_falsey
                subject.ensure_logged_in
                expect(subject.logged_in?).to be_falsey
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
                        password: 'doe',
                        submit_me: 'Login!'
                    }
                )

                expect(subject.logged_in?).to be_falsey
                subject.ensure_logged_in
                expect(subject.logged_in?).to be_truthy
            end
        end

        context 'when there is no login capability' do
            it 'returns nil' do
                expect(subject.can_login?).to be_falsey
                expect(subject.ensure_logged_in).to be_nil
            end
        end
    end

end
