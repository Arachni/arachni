require 'spec_helper'

describe Arachni::Framework do

    before( :all ) do
        @url   = web_server_url_for( :auditor )
        @f_url = web_server_url_for( :framework )

        @opts  = Arachni::Options.instance
    end

    before( :each ) do
        reset_options
        @opts.dir['reports'] = fixtures_path + '/reports/manager_spec/'
        @opts.dir['modules'] = fixtures_path + '/taint_module/'

        @f = Arachni::Framework.new
        @f.reset
    end
    after( :each ) { @f.reset }

    context 'when passed a block' do
        it 'executes it' do
            ran = false
            Arachni::Framework.new do |f|
                ran = true
            end

            ran.should be_true
        end

        it 'resets the framework' do
            Arachni::Modules.constants.include?( :Taint ).should be_false

            Arachni::Framework.new do |f|
                f.modules.load_all.should == %w(taint)
                Arachni::Modules.constants.include?( :Taint ).should be_true
            end

            Arachni::Modules.constants.include?( :Taint ).should be_false
        end
    end

    context 'when unable to get a response for the given URL' do
        context 'due to a network error' do
            it 'returns an empty sitemap and have failures' do
                @opts.url = 'http://blahaha'
                @opts.do_not_crawl

                @f.push_to_url_queue @opts.url
                @f.modules.load :taint
                @f.run
                @f.failures.should be_any
            end
        end

        context 'due to a server error' do
            it 'returns an empty sitemap and have failures' do
                @opts.url = @f_url + '/fail'
                @opts.do_not_crawl

                @f.push_to_url_queue @opts.url
                @f.modules.load :taint
                @f.run
                @f.failures.should be_any
            end
        end

        it "retries #{Arachni::Framework::AUDIT_PAGE_MAX_TRIES} times" do
            @opts.url = @f_url + '/fail_4_times'
            @opts.do_not_crawl

            @f.push_to_url_queue @opts.url
            @f.modules.load :taint
            @f.run
            @f.failures.should be_empty
        end
    end

    describe '#failures' do
        context 'when there are no failed requests' do
            it 'returns an empty array' do
                @opts.url = @f_url
                @opts.do_not_crawl

                @f.push_to_url_queue @opts.url
                @f.modules.load :taint
                @f.run
                @f.failures.should be_empty
            end
        end
        context 'when there are failed requests' do
            it 'returns an array containing the failed URLs' do
                @opts.url = @f_url + '/fail'
                @opts.do_not_crawl

                @f.push_to_url_queue @opts.url
                @f.modules.load :taint
                @f.run
                @f.failures.should be_any
            end
        end
    end

    describe '#opts' do
        it 'provides access to the framework options' do
            @f.opts.is_a?( Arachni::Options ).should be_true
        end

        describe '#exclude_binaries' do
            it 'excludes binary pages from the audit' do
                f = Arachni::Framework.new

                f.opts.url = @url + '/binary'
                f.opts.audit :links, :forms, :cookies
                f.modules.load :taint

                ok = false
                f.on_audit_page { ok = true }
                f.run
                ok.should be_true
                f.reset

                f.opts.url = @url + '/binary'
                f.opts.exclude_binaries = true
                f.modules.load :taint

                ok = true
                f.on_audit_page { ok = false }

                f.run
                f.reset
                ok.should be_true
            end
        end
        describe '#restrict_paths' do
            it 'serves as a replacement to crawling' do
                f = Arachni::Framework.new
                f.opts.url = @url
                f.opts.restrict_paths = %w(/elem_combo /log_remote_file_if_exists/true)
                f.opts.audit :links, :forms, :cookies
                f.modules.load :taint

                f.run

                sitemap = f.auditstore.sitemap.sort.map { |u| u.split( '?' ).first }
                sitemap.uniq.should == f.opts.restrict_paths.sort
                f.modules.clear
            end
        end
    end

    describe '#reports' do
        it 'provides access to the report manager' do
            @f.reports.is_a?( Arachni::Report::Manager ).should be_true
            @f.reports.available.sort.should == %w(afr foo).sort
        end
    end

    describe '#modules' do
        it 'provides access to the module manager' do
            @f.modules.is_a?( Arachni::Module::Manager ).should be_true
            @f.modules.available.should == %w(taint)
        end
    end

    describe '#plugins' do
        it 'provides access to the plugin manager' do
            @f.plugins.is_a?( Arachni::Plugin::Manager ).should be_true
            @f.plugins.available.sort.should ==
                %w(wait bad with_options distributable loop default spider_hook).sort
        end
    end

    describe '#http' do
        it 'provides access to the HTTP interface' do
            @f.http.is_a?( Arachni::HTTP::Client ).should be_true
        end
    end

    describe '#spider' do
        it 'provides access to the Spider' do
            @f.spider.is_a?( Arachni::Spider ).should be_true
        end
    end

    describe '#run' do

        it 'performs the audit' do
            @f.opts.url = @url + '/elem_combo'
            @f.opts.audit :links, :forms, :cookies
            @f.modules.load :taint
            @f.plugins.load :wait
            @f.reports.load :foo

            @f.status.should == 'ready'

            @f.pause
            @f.status.should == 'paused'

            @f.resume
            @f.status.should == 'ready'

            called = false
            t = Thread.new{
                @f.run {
                    called = true
                    @f.status.should == 'cleanup'
                }
            }

            raised = false
            begin
                Timeout.timeout( 10 ) {
                    sleep( 0.01 ) while @f.status == 'preparing'
                    sleep( 0.01 ) while @f.status == 'crawling'
                    sleep( 0.01 ) while @f.status == 'auditing'
                }
            rescue TimeoutError
                raised = true
            end

            raised.should be_false

            t.join
            called.should be_true

            @f.status.should == 'done'
            @f.auditstore.issues.size.should == 5

            @f.auditstore.plugins['wait'][:results].should == { stuff: true }

            File.exists?( 'afr' ).should be_true
            File.exists?( 'foo' ).should be_true
            File.delete( 'foo' )
            File.delete( 'afr' )
        end

        it 'handles heavy load' do
            @opts.dir['modules']  = fixtures_path + '/taint_module/'
            f = Arachni::Framework.new

            f.opts.url = web_server_url_for :framework_hpg
            f.opts.audit :links

            f.modules.load :taint

            f.run
            f.auditstore.issues.size.should == 500
            f.modules.clear
        end

        context 'when the page has a body which is' do
            context 'not empty' do
                it 'runs modules that audit the page body' do
                    @opts.dir['modules']  = fixtures_path + '/run_mod/'
                    f = Arachni::Framework.new

                    f.opts.audit :links
                    f.modules.load %w(body)

                    link = Arachni::Element::Link.new( 'http://test' )
                    p = Arachni::Page.new( url: 'http://test', body: 'stuff' )
                    f.push_to_page_queue( p )

                    f.run
                    f.auditstore.issues.size.should == 1
                    f.modules.clear
                end
            end
            context 'empty' do
                it 'skips modules that audit the page body' do
                    @opts.dir['modules']  = fixtures_path + '/run_mod/'
                    f = Arachni::Framework.new

                    f.opts.audit :links
                    f.modules.load %w(body)

                    link = Arachni::Element::Link.new( 'http://test' )
                    p = Arachni::Page.new( url: 'http://test', body: '' )
                    f.push_to_page_queue( p )

                    f.run
                    f.auditstore.issues.size.should == 0
                    f.modules.clear
                end
            end
        end

        context 'when auditing links is' do
            context 'enabled' do
                context 'and the page contains links' do
                    it 'runs modules that audit links' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit :links
                        f.modules.load %w(links forms cookies headers flch)

                        link = Arachni::Element::Link.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', links: [link] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'runs modules that audit path and server' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit :links
                        f.modules.load %w(path server)

                        link = Arachni::Element::Link.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', links: [link] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'runs modules that have not specified any elements' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit :links
                        f.modules.load %w(nil empty)

                        link = Arachni::Element::Link.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', links: [link] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 1
                        f.modules.clear
                    end
                end
            end

            context 'disabled' do
                context 'and the page contains links' do
                    it 'skips modules that audit links' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.dont_audit :links
                        f.modules.load %w(links forms cookies headers flch)

                        link = Arachni::Element::Link.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', links: [link] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 0
                        f.modules.clear
                    end

                    it 'runs modules that audit path and server' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.dont_audit :links
                        f.modules.load %w(path server)

                        link = Arachni::Element::Link.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', links: [link] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'runs modules that have not specified any elements' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.dont_audit :links
                        f.modules.load %w(nil empty)

                        link = Arachni::Element::Link.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', links: [link] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 1
                        f.modules.clear
                    end
                end
            end

        end

        context 'when auditing forms is' do
            context 'enabled' do
                context 'and the page contains forms' do
                    it 'runs modules that audit forms' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit :forms
                        f.modules.load %w(links forms cookies headers flch)

                        form = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', forms: [form] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'runs modules that audit path and server' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit :forms
                        f.modules.load %w(path server)

                        form = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', forms: [form] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'runs modules that have not specified any elements' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit :forms
                        f.modules.load %w(nil empty)

                        form = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', forms: [form] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 1
                        f.modules.clear
                    end
                end
            end

            context 'disabled' do
                context 'and the page contains forms' do
                    it 'skips modules that audit forms' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.dont_audit :forms
                        f.modules.load %w(links forms cookies headers flch)

                        form = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', forms: [form] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 0
                        f.modules.clear
                    end

                    it 'runs modules that audit path and server' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.dont_audit :forms
                        f.modules.load %w(path server)

                        form = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', forms: [form] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'runs modules that have not specified any elements' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.dont_audit :forms
                        f.modules.load %w(nil empty)

                        form = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', forms: [form] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 1
                        f.modules.clear
                    end
                end
            end

        end

        context 'when auditing cookies is' do
            context 'enabled' do
                context 'and the page contains cookies' do
                    it 'runs modules that audit cookies' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit :cookies
                        f.modules.load %w(links forms cookies headers flch)

                        cookie = Arachni::Element::Cookie.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', cookies: [cookie] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'runs modules that audit path and server' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit :cookies
                        f.modules.load %w(path server)

                        cookie = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', cookies: [cookie] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'runs modules that have not specified any elements' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit :cookies
                        f.modules.load %w(nil empty)

                        cookie = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', cookies: [cookie] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 1
                        f.modules.clear
                    end
                end
            end

            context 'disabled' do
                context 'and the page contains cookies' do
                    it 'skips modules that audit cookies' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.dont_audit :cookies
                        f.modules.load %w(links forms cookies headers flch)

                        cookie = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', cookies: [cookie] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 0
                        f.modules.clear
                    end

                    it 'runs modules that audit path and server' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.dont_audit :cookies
                        f.modules.load %w(path server)

                        cookie = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', cookies: [cookie] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'runs modules that have not specified any elements' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.dont_audit :cookies
                        f.modules.load %w(nil empty)

                        cookie = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', cookies: [cookie] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 1
                        f.modules.clear
                    end
                end
            end

        end

        context 'when auditing headers is' do
            context 'enabled' do
                context 'and the page contains headers' do
                    it 'runs modules that audit headers' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit :headers
                        f.modules.load %w(links forms cookies headers flch)

                        header = Arachni::Element::Cookie.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', headers: [header] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'runs modules that audit path and server' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit :headers
                        f.modules.load %w(path server)

                        header = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', headers: [header] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'runs modules that have not specified any elements' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit :headers
                        f.modules.load %w(nil empty)

                        header = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', headers: [header] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 1
                        f.modules.clear
                    end
                end
            end

            context 'disabled' do
                context 'and the page contains headers' do
                    it 'skips modules that audit headers' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.dont_audit :headers
                        f.modules.load %w(links forms cookies headers flch)

                        header = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', headers: [header] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 0
                        f.modules.clear
                    end

                    it 'runs modules that audit path and server' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.dont_audit :headers
                        f.modules.load %w(path server)

                        header = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', headers: [header] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'runs modules that have not specified any elements' do
                        @opts.dir['modules']  = fixtures_path + '/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.dont_audit :headers
                        f.modules.load %w(nil empty)

                        header = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', headers: [header] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 1
                        f.modules.clear
                    end
                end
            end

        end

        context 'when it has log-in capabilities and gets logged out' do
            it 'logs-in again before continuing with the audit' do
                f = Arachni::Framework.new
                url = web_server_url_for( :framework ) + '/'
                f.opts.url = "#{url}/congrats"

                f.opts.audit :links, :forms
                f.modules.load_all

                f.session.login_sequence = proc do
                    res = f.http.get( url, mode: :sync, follow_location: true )
                    return false if !res

                    login_form = f.forms_from_response( res ).first
                    next false if !login_form

                    login_form['username'] = 'john'
                    login_form['password'] = 'doe'
                    res = login_form.submit( mode: :sync, update_cookies: true, follow_location: false )
                    return false if !res

                    true
                end

                f.session.login_check = proc do
                    !!f.http.get( url, mode: :sync, follow_location: true ).
                        body.match( 'logged-in user' )
                end

                f.run
                f.auditstore.issues.size.should == 1
                f.reset
            end
        end
    end

    describe '#report_as' do
        before( :each ) do
            reset_options
            @new_framework = Arachni::Framework.new
        end

        context 'when passed a valid report name' do
            it 'returns the report as a string' do
                json = @new_framework.report_as( :json )
                JSON.load( json )['issues'].size.should == @new_framework.auditstore.issues.size
            end

            context 'which does not support the \'outfile\' option' do
                it 'raises Arachni::Component::Options::Error::Invalid' do
                    expect { @new_framework.report_as( :stdout ) }.to raise_error Arachni::Component::Options::Error::Invalid
                end
            end
        end

        context 'when passed an invalid report name' do
            it 'raises Arachni::Component::Error::NotFound' do
                expect { @new_framework.report_as( :blah ) }.to raise_error Arachni::Component::Error::NotFound
            end
        end
    end

    describe '#audit_page' do
        context 'when the page does not match exclusion criteria' do
            it 'audits it and returns true' do
                @f.opts.audit :links, :forms, :cookies

                @f.modules.load :taint

                @f.audit_page( Arachni::Page.from_url( @url + '/link' ) ).should be_true
                @f.auditstore.issues.size.should == 1
            end
        end
        context 'when the page matches exclusion criteria' do
            it 'does not audit it and returns false' do
                @f.opts.exclude << /link/
                @f.opts.audit :links, :forms, :cookies

                @f.modules.load :taint

                @f.audit_page( Arachni::Page.from_url( @url + '/link' ) ).should be_false
                @f.auditstore.issues.size.should == 0
            end
        end
    end

    describe 'link_count_limit_reached?' do
        context 'when the Options#link_count_limit has' do
            context 'been reached' do
                it 'returns true' do
                    Arachni::Framework.new do |f|
                        f.opts.url = web_server_url_for :framework_hpg
                        f.opts.audit :links
                        f.opts.link_count_limit = 10

                        f.link_count_limit_reached?.should be_false
                        f.run
                        f.link_count_limit_reached?.should be_true
                    end
                end
            end

            context 'not been reached' do
                it 'returns false' do
                    Arachni::Framework.new do |f|
                        f.opts.url = web_server_url_for :framework
                        f.opts.audit :links
                        f.opts.link_count_limit = 100

                        f.modules.load :taint

                        f.link_count_limit_reached?.should be_false
                        f.run
                        f.link_count_limit_reached?.should be_false
                    end
                end
            end

            context 'not been set' do
                it 'returns false' do
                    Arachni::Framework.new do |f|
                        f.opts.url = web_server_url_for :framework
                        f.opts.audit :links

                        f.modules.load :taint

                        f.link_count_limit_reached?.should be_false
                        f.run
                        f.link_count_limit_reached?.should be_false
                    end
                end
            end
        end
    end

    describe '#push_to_page_queue' do
        context 'when the page does not match exclusion criteria' do
            it 'pushes it to the page audit queue and returns true' do
                page = Arachni::Page.from_url( @url + '/train/true' )

                @f.opts.audit :links, :forms, :cookies
                @f.modules.load :taint

                @f.page_queue_total_size.should == 0
                @f.push_to_page_queue( page ).should be_true
                @f.run
                @f.auditstore.issues.size.should == 3
                @f.page_queue_total_size.should > 0
                @f.modules.clear
            end
        end
        context 'when the page matches exclusion criteria' do
            it 'does not push it to the page audit queue and returns false' do
                page = Arachni::Page.from_url( @url + '/train/true' )

                @f.opts.audit :links, :forms, :cookies
                @f.modules.load :taint

                @f.opts.exclude << /train/

                @f.page_queue_total_size.should == 0
                @f.push_to_page_queue( page ).should be_false
                @f.run
                @f.auditstore.issues.size.should == 0
                @f.page_queue_total_size.should == 0
                @f.modules.clear
            end
        end
    end

    describe '#push_to_url_queue' do
        it 'pushes a URL to the URL audit queue' do
            @f.opts.audit :links, :forms, :cookies
            @f.modules.load :taint

            @f.url_queue_total_size.should == 0
            @f.push_to_url_queue(  @url + '/link' )
            @f.run
            @f.auditstore.issues.size.should == 1
            @f.url_queue_total_size.should > 0
        end
    end

    describe '#stats' do
        it 'returns a hash with stats' do
            @f.stats.keys.sort.should == [ :requests, :responses, :time_out_count,
                :time, :avg, :sitemap_size, :auditmap_size, :progress, :curr_res_time,
                :curr_res_cnt, :curr_avg, :average_res_time, :max_concurrency, :current_page, :eta ].sort
        end
    end

    describe '#list_platforms' do
        it 'returns information about all valid platforms' do
            @f.list_platforms.should == YAML.load( '---
Operating systems:
  :unix: Generic Unix family
  :linux: Linux
  :bsd: Generic BSD family
  :solaris: Solaris
  :windows: MS Windows
Databases:
  :coldfusion: ColdFusion
  :db2: DB2
  :emc: EMC
  :informix: Informix
  :interbase: InterBase
  :mssql: MSSQL
  :mysql: MySQL
  :oracle: Oracle
  :pgsql: Postgresql
  :sqlite: SQLite
Web servers:
  :apache: Apache
  :iis: IIS
  :nginx: Nginx
  :tomcat: TomCat
  :jetty: Jetty
Programming languages:
  :asp: ASP
  :aspx: ASP.NET
  :jsp: JSP
  :perl: Perl
  :php: PHP
  :python: Python
  :ruby: Ruby
Frameworks:
  :rack: Rack
')
        end
    end

    describe '#list_modules' do
        it 'aliased to #lsmod return info on all modules' do
            @f.modules.load :taint
            info = @f.modules.values.first.info
            loaded = @f.modules.loaded

            mods = @f.list_modules
            mods.should == @f.lsmod

            @f.modules.loaded.should == loaded

            mods.size.should == 1
            mod = mods.first
            mod[:name].should == info[:name]
            mod[:mod_name].should == 'taint'
            mod[:shortname].should == mod[:mod_name]
            mod[:description].should == info[:description]
            mod[:author].should == [info[:author]].flatten
            mod[:version].should == info[:version]
            mod[:references].should == info[:references]
            mod[:targets].should == info[:targets]
            mod[:issue].should == info[:issue]
        end

        context 'when the #lsmod option is set' do
            it 'uses it to filter out modules that do not match it' do
                @f.opts.lsmod = 'boo'
                @f.list_modules.should == @f.lsmod
                @f.lsmod.size == 0

                @f.opts.lsmod = 'taint'
                @f.list_modules.should == @f.lsmod
                @f.lsmod.size == 1
            end
        end
    end

    describe '#list_plugins' do
        it 'aliased to #lsplug return info on all plugins' do
            loaded = @f.plugins.loaded

            @f.list_plugins.should == @f.lsplug

            @f.list_plugins.map { |r| r.delete( :path ); r }
                .sort_by { |e| e[:plug_name] }.should == YAML.load( '
---
- :name: \'\'
  :description: \'\'
  :author:
  - Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
  :version: \'0.1\'
  :plug_name: !binary |-
    YmFk
  :shortname: !binary |-
    YmFk
- :name: Default
  :description: Some description
  :author:
  - Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
  :version: \'0.1\'
  :options:
  - !ruby/object:Arachni::Component::Options::Int
    name: int_opt
    required: false
    desc: An integer.
    default: 4
    enums: []
  :plug_name: !binary |-
    ZGVmYXVsdA==
  :shortname: !binary |-
    ZGVmYXVsdA==
- :name: Distributable
  :description: \'\'
  :author:
  - Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
  :version: \'0.1\'
  :issue:
    :tags:
    - distributable_string
    - :distributable_sym
  :plug_name: !binary |-
    ZGlzdHJpYnV0YWJsZQ==
  :shortname: !binary |-
    ZGlzdHJpYnV0YWJsZQ==
- :name: \'\'
  :description: \'\'
  :author:
  - Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
  :version: \'0.1\'
  :plug_name: !binary |-
    bG9vcA==
  :shortname: !binary |-
    bG9vcA==
- :name: SpiderHook
  :description: \'\'
  :author:
  - Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
  :version: \'0.1\'
  :plug_name: !binary |-
    c3BpZGVyX2hvb2s=
  :shortname: !binary |-
    c3BpZGVyX2hvb2s=
- :name: Wait
  :description: \'\'
  :tags:
  - wait_string
  - :wait_sym
  :author:
  - Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
  :version: \'0.1\'
  :plug_name: !binary |-
    d2FpdA==
  :shortname: !binary |-
    d2FpdA==
- :name: Component
  :description: Component with options
  :author:
  - Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
  :version: \'0.1\'
  :options:
  - !ruby/object:Arachni::Component::Options::String
    name: req_opt
    required: true
    desc: Required option
    default:
    enums: []
  - !ruby/object:Arachni::Component::Options::String
    name: opt_opt
    required: false
    desc: Optional option
    default:
    enums: []
  - !ruby/object:Arachni::Component::Options::String
    name: default_opt
    required: false
    desc: Option with default value
    default: value
    enums: []
  :plug_name: !binary |-
    d2l0aF9vcHRpb25z
  :shortname: !binary |-
    d2l0aF9vcHRpb25z
' ).sort_by { |e| e[:plug_name] }
            @f.plugins.loaded.should == loaded
        end

        context 'when the #lsplug option is set' do
            it 'uses it to filter out plugins that do not match it' do
                @f.opts.lsplug = 'bad|foo'
                @f.list_plugins.should == @f.lsplug
                @f.lsplug.size == 2

                @f.opts.lsplug = 'boo'
                @f.list_plugins.should == @f.lsplug
                @f.lsplug.size == 0
            end
        end
    end

    describe '#list_reports' do
        it 'returns info on all reports' do
            loaded = @f.reports.loaded
            @f.list_reports.should == @f.lsrep
            @f.list_reports.map { |r| r[:options] = []; r.delete( :path ); r }
                .sort_by { |e| e[:rep_name] }.should == YAML.load( '
---
- :name: Report abstract class.
  :options: []

  :description: This class should be extended by all reports.
  :author:
  - zapotek
  :version: 0.1.1
  :rep_name: afr
  :shortname: afr
- :name: Report abstract class.
  :options: []

  :description: This class should be extended by all reports.
  :author:
  - zapotek
  :version: 0.1.1
  :rep_name: foo
  :shortname: foo
').sort_by { |e| e[:rep_name] }
            @f.reports.loaded.should == loaded
        end

        context 'when the #lsrep option is set' do
            it 'uses it to filter out reports that do not match it' do
                @f.opts.lsrep = 'foo'
                @f.list_reports.should == @f.lsrep
                @f.lsrep.size == 1

                @f.opts.lsrep = 'boo'
                @f.list_reports.should == @f.lsrep
                @f.lsrep.size == 0
            end
        end
    end

end
