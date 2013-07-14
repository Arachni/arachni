require 'spec_helper'

describe Arachni::Session do

    before( :all ) do
        @url = web_server_url_for( :session )
        @opts = Arachni::Options.instance
    end

    after( :each ) do
        Arachni::Options.reset
        Arachni::HTTP.reset
    end

    def new_session
        Arachni::Session.new
    end

    describe '#opts' do
        describe '#login_check_url and #login_check_pattern' do
            it 'sets a login check' do
                s = new_session
                s.opts.url = @url

                s.has_login_sequence?.should be_false
                s.login_sequence = proc do
                    res = s.http.get( @url, async: false, follow_location: true ).response
                    return false if !res

                    login_form = s.forms_from_response( res ).first
                    next false if !login_form

                    login_form['username'] = 'john'
                    login_form['password'] = 'doe'
                    res = login_form.submit( async: false, update_cookies: true, follow_location: false ).response
                    return false if !res

                    true
                end
                s.has_login_sequence?.should be_true

                s.has_login_check?.should be_false
                s.opts.login_check_url     = @url
                s.opts.login_check_pattern = 'logged-in user'
                s.has_login_check?.should be_true

                s.logged_in?.should be_false
                s.login.should be_true
                s.logged_in?.should be_true

                bool = false
                s.logged_in? { |b| bool = b }
                s.http.run
                bool.should be_true

                not_bool = true
                s.logged_in?( no_cookiejar: true ) { |b| not_bool = b }
                s.http.run
                not_bool.should be_false
            end
        end
    end

    describe '#cookies' do
        it 'returns session cookies' do
            s = new_session
            s.http.get @url + '/cookies', async: false, update_cookies: true

            s.cookies.select { |c| c.name == 'rack.session' }.size == 1
            s.cookies.select { |c| c.name == 'session_cookie' }.size == 1

            s.can_login?.should be_false
            s.has_login_sequence?.should be_false

            s.login_form = s.find_login_form( url: @url + '/nonce_login' ).
                update( username: 'nonce_john', password: 'nonce_doe' )

            # lets invalidate the form nonce now
            # (to make sure that it will be refreshed before logging in)
            s.http.get @url + '/nonce_login', async: false

            s.has_login_sequence?.should be_true

            s.set_login_check @url + '/with_nonce', 'logged-in user'

            cookie = nil
            s.cookie { |c| cookie = c }
            s.http.run

            cookie.name.should == 'rack.session'

            s.can_login?.should be_true
            s.logged_in?.should be_false
        end
        context 'when called without having configured a login check' do
            it 'should raise an exception' do
                trigger = proc { new_session.cookie }

                raised = false
                begin
                    trigger.call
                rescue Arachni::Error
                    raised = true
                end
                raised.should be_true

                raised = false
                begin
                    trigger.call
                rescue Arachni::Session::Error
                    raised = true
                end
                raised.should be_true

                raised = false
                begin
                    trigger.call
                rescue Arachni::Session::Error::NoLoginCheck
                    raised = true
                end
                raised.should be_true
            end
        end
    end

    describe '#find_login_form' do
        before { @id = "#{@url}/login::post::[\"password\", \"token\", \"username\"]" }
        context 'when passed an array of :pages' do
            it 'should go through its forms and locate the login one' do
                p = Arachni::Page.from_url( @url + '/login' )
                s = new_session

                s.find_login_form( pages: [ p, p ] ).id.should == @id
            end
        end
        context 'when passed an array of :forms' do
            it 'should go through its forms and locate the login one' do
                p = Arachni::Page.from_url( @url + '/login' )
                s = new_session

                s.find_login_form( forms: p.forms ).id.should == @id
            end
        end
        context 'when passed a url' do
            it 'store the cookies set by that url' do
                Arachni::HTTP.cookies.should be_empty

                new_session.find_login_form( url: @url + '/login' ).id.should == @id

                Arachni::HTTP.cookies.find do |c|
                    c.name == 'you_need_to' && c.value == 'preserve this'
                end.should be_kind_of Arachni::Cookie
            end

            context 'and called without a block' do
                it 'should operate in blocking mode, go through its forms and locate the login one' do
                    s = new_session
                    s.find_login_form( url: @url + '/login' ).id.should == @id
                end
            end
            context 'and called with a block' do
                it 'should operate in async mode, go through its forms, locate the login one and pass it to the block' do
                    s = new_session

                    form = nil
                    s.find_login_form( url: @url + '/login' ) { |f| form = f }
                    s.http.run

                    form.id.should == @id
                end
            end
        end
        context 'when passed an array of :inputs' do
            it 'should use them to narrow down the list' do
                new_session.find_login_form( url: @url + '/multiple',
                                             inputs: :token ).id.should == @id
            end
        end
        context 'when passed an :action' do
            context Regexp do
                it 'should use it to match against form actions' do
                    new_session.find_login_form( url: @url + '/multiple',
                                                 action: /login/ ).id.should == @id
                end
            end
            context String do
                it 'should use it to match against form actions' do
                    new_session.find_login_form( url: @url + '/multiple',
                                                 action: "#{@url}/login" ).
                        id.should == @id
                end
            end
        end

    end

    describe '#login_form=' do
        it 'sets a login form' do
            s = new_session

            s.can_login?.should be_false
            s.has_login_sequence?.should be_false

            s.login_form = s.find_login_form( url: @url + '/nonce_login' ).
                update( username: 'nonce_john', password: 'nonce_doe' )

            # lets invalidate the form nonce now
            # (to make sure that it will be refreshed before logging in)
            s.http.get @url + '/nonce_login', async: false

            s.has_login_sequence?.should be_true

            s.set_login_check @url + '/with_nonce', 'logged-in user'

            s.can_login?.should be_true
            s.logged_in?.should be_false

            s.login
            s.logged_in?.should be_true
        end
    end

    describe '#can_login?' do
        context 'when there are no login sequences' do
            it 'returns false' do
                new_session.can_login?.should be_false
            end
        end
        context 'when there are login sequences' do
            it 'returns true' do
                s = new_session
                s.login_sequence = proc {}
                s.login_check = proc {}
                s.can_login?.should be_true
            end
        end
    end

    describe '#login' do
        context 'when there is no login capability' do
            it 'returns nil' do
                s = new_session
                s.can_login?.should be_false
                s.has_login_sequence?.should be_false
                s.login.should be_nil
            end
        end
    end

    describe '#logged_in?' do
        context 'when there is no login check' do
            it 'returns nil' do
                s = new_session
                s.can_login?.should be_false
                s.has_login_check?.should be_false
                s.logged_in?.should be_nil
            end
        end
    end

    describe '#ensure_logged_in' do
        context 'when there is no login capability' do
            it 'returns nil' do
                s = new_session
                s.can_login?.should be_false
                s.ensure_logged_in.should be_nil
            end
        end
    end

    describe '#login_sequence' do
        context 'when a block is given' do
            it 'sets it as a login sequence' do
                s = new_session
                s.login_sequence { :yeah! }
                s.login_sequence.call.should == :yeah!
                s.login.should == :yeah!
            end
        end
    end

    describe '#login_check' do
        context 'when a block is given' do
            it 'sets it as a login sequence' do
                s = new_session
                s.login_check { :yeah! }
                s.login_check.call.should == :yeah!
                s.logged_in?.should == :yeah!
            end
        end
    end

    describe '#set_login_check' do
        it 'sets a login check using a URL and regular expression' do
            s = new_session
            url = web_server_url_for( :session ) + '/'
            s.opts.url = "#{url}/congrats"

            s.has_login_sequence?.should be_false
            s.login_sequence = proc do
                res = s.http.get( url, async: false, follow_location: true ).response
                return false if !res

                login_form = s.forms_from_response( res ).first
                next false if !login_form

                login_form['username'] = 'john'
                login_form['password'] = 'doe'
                res = login_form.submit( async: false, update_cookies: true, follow_location: false ).response
                return false if !res

                true
            end
            s.has_login_sequence?.should be_true

            s.has_login_check?.should be_false
            s.set_login_check( url, 'logged-in user' )
            s.has_login_check?.should be_true

            s.logged_in?.should be_false
            s.login.should be_true
            s.logged_in?.should be_true

            bool = false
            s.logged_in? { |b| bool = b }
            s.http.run
            bool.should be_true

            not_bool = true
            s.logged_in?( no_cookiejar: true ) { |b| not_bool = b }
            s.http.run
            not_bool.should be_false
        end
    end

end
