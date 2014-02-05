require 'spec_helper'

describe Arachni::Framework do

    before( :all ) do
        @url   = web_server_url_for( :auditor )
        @f_url = web_server_url_for( :framework )

        @opts  = Arachni::Options.instance
    end

    before( :each ) do
        reset_options
        @opts.paths.reports = fixtures_path + '/reports/manager_spec/'
        @opts.paths.checks  = fixtures_path + '/taint_check/'

        @f = Arachni::Framework.new
        @f.opts.url = @url
    end
    after( :each ) do
        @f.clean_up

        if ::EM.reactor_running?
            ::EM.stop
            sleep 0.1 while ::EM.reactor_running?
        end

        @f.reset
    end

    context 'when passed a block' do
        it 'executes it' do
            ran = false
            Arachni::Framework.new do |f|
                ran = true
            end

            ran.should be_true
        end

        it 'resets the framework' do
            Arachni::Checks.constants.include?( :Taint ).should be_false

            Arachni::Framework.new do |f|
                f.checks.load_all.should == %w(taint)
                Arachni::Checks.constants.include?( :Taint ).should be_true
            end

            Arachni::Checks.constants.include?( :Taint ).should be_false
        end
    end

    context 'when unable to get a response for the given URL' do
        context 'due to a network error' do
            it 'returns an empty sitemap and have failures' do
                @opts.url = 'http://blahaha'
                @opts.scope.do_not_crawl

                @f.push_to_url_queue @opts.url
                @f.checks.load :taint
                @f.run
                @f.failures.should be_any
            end
        end

        context 'due to a server error' do
            it 'returns an empty sitemap and have failures' do
                @opts.url = @f_url + '/fail'
                @opts.scope.do_not_crawl

                @f.push_to_url_queue @opts.url
                @f.checks.load :taint
                @f.run
                @f.failures.should be_any
            end
        end

        it "retries #{Arachni::Framework::AUDIT_PAGE_MAX_TRIES} times" do
            @opts.url = @f_url + '/fail_4_times'
            @opts.scope.do_not_crawl

            @f.push_to_url_queue @opts.url
            @f.checks.load :taint
            @f.run
            @f.failures.should be_empty
        end
    end

    describe '#failures' do
        context 'when there are no failed requests' do
            it 'returns an empty array' do
                @opts.url = @f_url
                @opts.scope.do_not_crawl

                @f.push_to_url_queue @opts.url
                @f.checks.load :taint
                @f.run
                @f.failures.should be_empty
            end
        end
        context 'when there are failed requests' do
            it 'returns an array containing the failed URLs' do
                @opts.url = @f_url + '/fail'
                @opts.scope.do_not_crawl

                @f.push_to_url_queue @opts.url
                @f.checks.load :taint
                @f.run
                @f.failures.should be_any
            end
        end
    end

    describe '#opts' do
        it 'provides access to the framework options' do
            @f.opts.is_a?( Arachni::Options ).should be_true
        end

        describe '#audit.exclude_binaries' do
            it 'excludes binary pages from the audit' do
                ok = false
                Arachni::Framework.new do |f|
                    f.opts.url = @url + '/binary'
                    f.opts.audit.elements :links, :forms, :cookies
                    f.checks.load :taint

                    f.on_audit_page { ok = true }
                    f.run
                end
                ok.should be_true

                ok = true
                Arachni::Framework.new do |f|
                    f.opts.url = @url + '/binary'
                    f.opts.audit.exclude_binaries = true
                    f.checks.load :taint

                    f.on_audit_page { ok = false }
                    f.run
                end
                ok.should be_true
            end
        end

        describe '#scope.restrict_paths' do
            it 'serves as a replacement to crawling' do
                Arachni::Framework.new do |f|
                    f.opts.url = @url
                    f.opts.scope.restrict_paths = %w(/elem_combo /log_remote_file_if_exists/true)
                    f.opts.audit.elements :links, :forms, :cookies
                    f.checks.load :taint

                    f.run

                    sitemap = f.auditstore.sitemap.map { |u, _| u.split( '?' ).first }
                    sitemap.sort.uniq.should ==
                        f.opts.scope.restrict_paths.map { |p| f.to_absolute( p ) }.sort
                end
            end
        end
    end

    describe '#sitemap' do
        it 'returns a hash with covered URLs and HTTP status codes' do
            Arachni::Framework.new do |f|
                f.opts.url = "#{@url}/elem_combo"
                f.opts.audit.elements :links, :forms, :cookies
                f.checks.load :taint

                f.run
                f.sitemap.should == {
                    "#{@url}/elem_combo" => 200,
                    "#{@url}/elem_combo?link_input=link_blah" => 200,
                    "#{@url}/elem_combo?link_input=--seed" => 200,
                    "#{@url}/elem_combo?form_input=--seed" => 200,
                    "#{@url}/elem_combo?link_input=--seed&form_input=form_blah" => 200
                }
            end
        end
    end

    describe '#reports' do
        it 'provides access to the report manager' do
            @f.reports.is_a?( Arachni::Report::Manager ).should be_true
            @f.reports.available.sort.should == %w(afr foo).sort
        end
    end

    describe '#checks' do
        it 'provides access to the check manager' do
            @f.checks.is_a?( Arachni::Check::Manager ).should be_true
            @f.checks.available.should == %w(taint)
        end
    end

    describe '#plugins' do
        it 'provides access to the plugin manager' do
            @f.plugins.is_a?( Arachni::Plugin::Manager ).should be_true
            @f.plugins.available.sort.should ==
                %w(wait bad with_options distributable loop default).sort
        end
    end

    describe '#http' do
        it 'provides access to the HTTP interface' do
            @f.http.is_a?( Arachni::HTTP::Client ).should be_true
        end
    end

    describe '#run' do
        it 'performs the audit' do
            @f.opts.url = @url + '/elem_combo'
            @f.opts.audit.elements :links, :forms, :cookies
            @f.checks.load :taint
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
            @f.auditstore.issues.size.should == 3

            @f.auditstore.plugins['wait'][:results].should == { stuff: true }

            File.exists?( 'afr' ).should be_true
            File.exists?( 'foo' ).should be_true
            File.delete( 'foo' )
            File.delete( 'afr' )
        end

        it 'handles heavy load' do
            @opts.paths.checks  = fixtures_path + '/taint_check/'
            f = Arachni::Framework.new

            f.opts.url = web_server_url_for :framework_hpg
            f.opts.audit.elements :links

            f.checks.load :taint

            f.run
            f.auditstore.issues.size.should == 500
            f.checks.clear
        end

        it 'handles pages with JavaScript code' do
            Arachni::Framework.new do |f|
                f.opts.url = @url + '/with_javascript'
                f.opts.audit.elements :links, :forms, :cookies

                f.checks.load :taint
                f.run

                f.auditstore.issues.
                    map { |i| i.variations.first.vector.affected_input_name }.sort.should ==
                    %w(link_input form_input cookie_input).sort
            end
        end

        it 'handles AJAX' do
            Arachni::Framework.new do |f|
                f.opts.url = @url + '/with_ajax'
                f.opts.audit.elements :links, :forms, :cookies

                f.checks.load :taint
                f.run

                f.auditstore.issues.
                    map { |i| i.variations.first.vector.affected_input_name }.sort.should ==
                    %w(link_input form_input cookie_taint).sort
            end
        end

        context 'when it has log-in capabilities and gets logged out' do
            it 'logs-in again before continuing with the audit' do
                f = Arachni::Framework.new
                url = web_server_url_for( :framework ) + '/'
                f.opts.url = "#{url}/congrats"

                f.opts.audit.elements :links, :forms
                f.checks.load_all

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
        it 'updates the #sitemap with the DOM URL' do
            @f.opts.audit.elements :links, :forms, :cookies
            @f.checks.load :taint

            @f.sitemap.should be_empty

            page = Arachni::Page.from_url( @url + '/link' )
            page.dom.url = @url + '/link/#/stuff'

            @f.audit_page page
            @f.sitemap.should include @url + '/link/#/stuff'
        end

        it 'returns true' do
            @f.audit_page( Arachni::Page.from_url( @url + '/link' ) ).should be_true
        end

        context 'when auditing' do
            before { @opts.paths.checks = fixtures_path + '/run_check/' }

            context 'a page with a body which is' do
                context 'not empty' do
                    it 'runs checks that audit the page body' do
                        Arachni::Framework.new do |f|
                            f.opts.url = @url
                            f.opts.audit.elements :links
                            f.checks.load %w(body)

                            p = Arachni::Page.from_data( url: @url, body: 'stuff' )
                            f.audit_page( p )
                            f.auditstore.issues.size.should == 1
                        end
                    end
                end
                context 'empty' do
                    it 'skips checks that audit the page body' do
                        Arachni::Framework.new do |f|
                            f.opts.url = @url
                            f.opts.audit.elements :links
                            f.checks.load %w(body)

                            p = Arachni::Page.from_data( url: @url, body: '' )
                            f.audit_page( p )
                            f.auditstore.issues.size.should == 0
                        end
                    end
                end
            end

            context 'links is' do
                context 'enabled' do
                    context 'and the page contains links' do
                        it 'runs checks that audit links' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.elements :links
                                f.checks.load %w(links forms cookies headers flch)

                                link = Arachni::Element::Link.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, links: [link] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 2
                            end
                        end

                        it 'runs checks that audit path and server' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.elements :links
                                f.checks.load %w(path server)

                                link = Arachni::Element::Link.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, links: [link] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 2
                            end
                        end

                        it 'runs checks that have not specified any elements' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.elements :links
                                f.checks.load %w(nil empty)

                                link = Arachni::Element::Link.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, links: [link] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 1
                            end
                        end
                    end
                end

                context 'disabled' do
                    context 'and the page contains links' do
                        it 'skips checks that audit links' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.skip_elements :links
                                f.checks.load %w(links forms cookies headers flch)

                                link = Arachni::Element::Link.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, links: [link] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 0
                            end
                        end

                        it 'runs checks that audit path and server' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.skip_elements :links
                                f.checks.load %w(path server)

                                link = Arachni::Element::Link.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, links: [link] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 2
                            end
                        end

                        it 'runs checks that have not specified any elements' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.skip_elements :links
                                f.checks.load %w(nil empty)

                                link = Arachni::Element::Link.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, links: [link] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 1
                            end
                        end
                    end
                end
            end

            context 'forms is' do
                context 'enabled' do
                    context 'and the page contains forms' do
                        it 'runs checks that audit forms' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.elements :forms
                                f.checks.load %w(links forms cookies headers flch)

                                form = Arachni::Element::Form.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, forms: [form] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 2
                            end
                        end

                        it 'runs checks that audit path and server' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.elements :forms
                                f.checks.load %w(path server)

                                form = Arachni::Element::Form.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, forms: [form] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 2
                            end
                        end

                        it 'runs checks that have not specified any elements' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.elements :forms
                                f.checks.load %w(nil empty)

                                form = Arachni::Element::Form.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, forms: [form] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 1
                            end
                        end
                    end
                end

                context 'disabled' do
                    context 'and the page contains forms' do
                        it 'skips checks that audit forms' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.skip_elements :forms
                                f.checks.load %w(links forms cookies headers flch)

                                form = Arachni::Element::Form.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, forms: [form] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 0
                            end
                        end

                        it 'runs checks that audit path and server' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.skip_elements :forms
                                f.checks.load %w(path server)

                                form = Arachni::Element::Form.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, forms: [form] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 2
                            end
                        end

                        it 'runs checks that have not specified any elements' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.skip_elements :forms
                                f.checks.load %w(nil empty)

                                form = Arachni::Element::Form.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, forms: [form] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 1
                            end
                        end
                    end
                end
            end

            context 'cookies is' do
                context 'enabled' do
                    context 'and the page contains cookies' do
                        it 'runs checks that audit cookies' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.elements :cookies
                                f.checks.load %w(links forms cookies headers flch)

                                cookie = Arachni::Element::Cookie.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, cookies: [cookie] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 2
                            end
                        end

                        it 'runs checks that audit path and server' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.elements :cookies
                                f.checks.load %w(path server)

                                cookie = Arachni::Element::Form.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, cookies: [cookie] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 2
                            end
                        end

                        it 'runs checks that have not specified any elements' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.elements :cookies
                                f.checks.load %w(nil empty)

                                cookie = Arachni::Element::Form.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, cookies: [cookie] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 1
                            end
                        end
                    end
                end

                context 'disabled' do
                    context 'and the page contains cookies' do
                        it 'skips checks that audit cookies' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.skip_elements :cookies
                                f.checks.load %w(links forms cookies headers flch)

                                cookie = Arachni::Element::Form.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, cookies: [cookie] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 0
                            end
                        end

                        it 'runs checks that audit path and server' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.skip_elements :cookies
                                f.checks.load %w(path server)

                                cookie = Arachni::Element::Form.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, cookies: [cookie] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 2
                            end
                        end

                        it 'runs checks that have not specified any elements' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.skip_elements :cookies
                                f.checks.load %w(nil empty)

                                cookie = Arachni::Element::Form.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, cookies: [cookie] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 1
                            end
                        end
                    end
                end

            end

            context 'headers is' do
                context 'enabled' do
                    context 'and the page contains headers' do
                        it 'runs checks that audit headers' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.elements :headers
                                f.checks.load %w(links forms cookies headers flch)

                                header = Arachni::Element::Cookie.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, headers: [header] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 2
                            end
                        end

                        it 'runs checks that audit path and server' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.elements :headers
                                f.checks.load %w(path server)

                                header = Arachni::Element::Form.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, headers: [header] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 2
                            end
                        end

                        it 'runs checks that have not specified any elements' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.elements :headers
                                f.checks.load %w(nil empty)

                                header = Arachni::Element::Form.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, headers: [header] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 1
                            end
                        end
                    end
                end

                context 'disabled' do
                    context 'and the page contains headers' do
                        it 'skips checks that audit headers' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.skip_elements :headers
                                f.checks.load %w(links forms cookies headers flch)

                                header = Arachni::Element::Form.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, headers: [header] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 0
                            end
                        end

                        it 'runs checks that audit path and server' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.skip_elements :headers
                                f.checks.load %w(path server)

                                header = Arachni::Element::Form.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, headers: [header] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 2
                            end
                        end

                        it 'runs checks that have not specified any elements' do
                            Arachni::Framework.new do |f|
                                f.opts.url = @url
                                f.opts.audit.skip_elements :headers
                                f.checks.load %w(nil empty)

                                header = Arachni::Element::Form.new( url: @url )
                                p = Arachni::Page.from_data( url: @url, headers: [header] )
                                f.audit_page( p )
                                f.auditstore.issues.size.should == 1
                            end
                        end
                    end
                end
            end
        end

        context 'when the page contains JavaScript code' do
            it 'analyzes the DOM and pushes new pages to the page queue' do
                Arachni::Framework.new do |f|
                    f.opts.audit.elements :links, :forms, :cookies
                    f.checks.load :taint

                    f.page_queue_total_size.should == 0

                    f.audit_page( Arachni::Page.from_url( @url + '/with_javascript' ) )

                    sleep 0.1 while f.wait_for_browser?

                    f.page_queue_total_size.should > 0
                end
            end

            it 'analyzes the DOM and pushes new paths to the url queue' do
                Arachni::Framework.new do |f|
                    f.opts.url = @url
                    f.opts.audit.elements :links, :forms, :cookies
                    f.checks.load :taint

                    f.url_queue_total_size.should == 0

                    f.audit_page( Arachni::Page.from_url( @url + '/with_javascript' ) )

                    sleep 0.1 while f.wait_for_browser?

                    f.url_queue_total_size.should == 2
                end
            end

            context 'when the DOM depth limit has been reached' do
                it 'does not analyze the DOM' do
                    Arachni::Framework.new do |f|
                        f.opts.url = @url

                        f.opts.audit.elements :links, :forms, :cookies
                        f.checks.load :taint
                        f.opts.scope.dom_depth_limit = 1
                        f.url_queue_total_size.should == 0
                        f.audit_page( Arachni::Page.from_url( @url + '/with_javascript' ) ).should be_true
                        sleep 0.1 while f.wait_for_browser?
                        f.url_queue_total_size.should == 2

                        f.reset

                        f.opts.audit.elements :links, :forms, :cookies
                        f.checks.load :taint
                        f.opts.scope.dom_depth_limit = 1
                        f.url_queue_total_size.should == 0

                        page = Arachni::Page.from_url( @url + '/with_javascript' )
                        page.dom.push_transition page: :load

                        f.audit_page( page ).should be_true
                        sleep 0.1 while f.wait_for_browser?
                        f.url_queue_total_size.should == 0
                    end
                end
            end
        end

        context 'when the page DOM depth limit has been exceeded' do
            it 'returns false' do
                page = Arachni::Page.from_data(
                    url:         @url,
                    dom:         {
                        transitions: [
                            { page: :load },
                            { "<a href='javascript:click();'>" => :click },
                            { "<button dblclick='javascript:doubleClick();'>" => :ondblclick }
                        ]
                    }
                )

                f = Arachni::Framework.new
                f.opts.scope.dom_depth_limit = 10
                f.audit_page( page ).should be_true

                f.opts.scope.dom_depth_limit = 2
                f.audit_page( page ).should be_false

                f.clean_up
                f.reset
            end
        end

        context 'when the page matches exclusion criteria' do
            it 'does not audit it' do
                @f.opts.scope.exclude_path_patterns << /link/
                @f.opts.audit.elements :links, :forms, :cookies

                @f.checks.load :taint

                @f.audit_page( Arachni::Page.from_url( @url + '/link' ) )
                @f.auditstore.issues.size.should == 0
            end

            it 'returns false' do
                @f.opts.scope.exclude_path_patterns << /link/
                @f.audit_page( Arachni::Page.from_url( @url + '/link' ) ).should be_false
            end
        end
    end

    describe '#page_limit_reached?' do
        context 'when the Options#scope_page_limit has' do
            context 'been reached' do
                it 'returns true' do
                    Arachni::Framework.new do |f|
                        f.opts.url = web_server_url_for :framework_hpg
                        f.opts.audit.elements :links
                        f.opts.scope.page_limit = 10

                        f.page_limit_reached?.should be_false
                        f.run
                        f.page_limit_reached?.should be_true

                        f.sitemap.size.should == 10
                    end
                end
            end

            context 'not been reached' do
                it 'returns false' do
                    Arachni::Framework.new do |f|
                        f.opts.url = web_server_url_for :framework
                        f.opts.audit.elements :links
                        f.opts.scope.page_limit = 100

                        f.checks.load :taint

                        f.page_limit_reached?.should be_false
                        f.run
                        f.page_limit_reached?.should be_false
                    end
                end
            end

            context 'not been set' do
                it 'returns false' do
                    Arachni::Framework.new do |f|
                        f.opts.url = web_server_url_for :framework
                        f.opts.audit.elements :links

                        f.checks.load :taint

                        f.page_limit_reached?.should be_false
                        f.run
                        f.page_limit_reached?.should be_false
                    end
                end
            end
        end
    end

    describe '#push_to_page_queue' do
        it 'pushes it to the page audit queue and returns true' do
            page = Arachni::Page.from_url( @url + '/train/true' )

            @f.opts.audit.elements :links, :forms, :cookies
            @f.checks.load :taint

            @f.page_queue_total_size.should == 0
            @f.push_to_page_queue( page ).should be_true
            @f.run

            @f.auditstore.issues.size.should == 2
            @f.page_queue_total_size.should > 0
        end

        it 'updates the #sitemap with the DOM URL' do
            @f.opts.audit.elements :links, :forms, :cookies
            @f.checks.load :taint

            @f.sitemap.should be_empty

            page = Arachni::Page.from_url( @url + '/link' )
            page.dom.url = @url + '/link/#/stuff'

            @f.push_to_page_queue page
            @f.sitemap.should include @url + '/link/#/stuff'
        end

        context 'when the page has already been seen' do
            it 'ignores it' do
                page = Arachni::Page.from_url( @url + '/stuff' )

                @f.page_queue_total_size.should == 0
                @f.push_to_page_queue( page )
                @f.push_to_page_queue( page )
                @f.push_to_page_queue( page )
                @f.page_queue_total_size.should == 1
            end

            it 'returns false' do
                page = Arachni::Page.from_url( @url + '/stuff' )

                @f.page_queue_total_size.should == 0
                @f.push_to_page_queue( page ).should be_true
                @f.push_to_page_queue( page ).should be_false
                @f.push_to_page_queue( page ).should be_false
                @f.page_queue_total_size.should == 1
            end
        end

        context 'when the page matches exclusion criteria' do
            it 'ignores it' do
                page = Arachni::Page.from_url( @url + '/train/true' )

                @f.opts.audit.elements :links, :forms, :cookies
                @f.checks.load :taint

                @f.opts.scope.exclude_path_patterns << /train/

                @f.page_queue_total_size.should == 0
                @f.push_to_page_queue( page )
                @f.run
                @f.auditstore.issues.size.should == 0
                @f.page_queue_total_size.should == 0
                @f.checks.clear
            end

            it 'returns false' do
                page = Arachni::Page.from_url( @url + '/train/true' )
                @f.opts.scope.exclude_path_patterns << /train/
                @f.page_queue_total_size.should == 0
                @f.push_to_page_queue( page ).should be_false
                @f.page_queue_total_size.should == 0
            end
        end
    end

    describe '#push_to_url_queue' do
        it 'pushes a URL to the URL audit queue' do
            @f.opts.audit.elements :links, :forms, :cookies
            @f.checks.load :taint

            @f.url_queue_total_size.should == 0
            @f.push_to_url_queue(  @url + '/link' ).should be_true
            @f.run

            @f.auditstore.issues.size.should == 1
            @f.url_queue_total_size.should == 3
        end

        context 'when the URL has already been seen' do
            it 'returns false' do
                @f.push_to_url_queue(  @url + '/link' ).should be_true
                @f.push_to_url_queue(  @url + '/link' ).should be_false
            end

            it 'ignores it' do
                @f.url_queue_total_size.should == 0
                @f.push_to_url_queue(  @url + '/link' )
                @f.push_to_url_queue(  @url + '/link' )
                @f.push_to_url_queue(  @url + '/link' )
                @f.url_queue_total_size.should == 1
            end
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
            @f.list_platforms.should == {
                'Operating systems' => {
                    unix:    'Generic Unix family',
                    linux:   'Linux',
                    bsd:     'Generic BSD family',
                    solaris: 'Solaris',
                    windows: 'MS Windows'
                },
                'Databases' => {
                    access:     'MS Access',
                    coldfusion: 'ColdFusion',
                    db2:        'DB2',
                    emc:        'EMC',
                    firebird:   'Firebird',
                    frontbase:  'Frontbase',
                    hsqldb:     'HSQLDB',
                    informix:   'Informix',
                    ingres:     'IngresDB',
                    interbase:  'InterBase',
                    maxdb:      'SaP Max DB',
                    mssql:      'MSSQL',
                    mysql:      'MySQL',
                    oracle:     'Oracle',
                    pgsql:      'Postgresql',
                    sqlite:     'SQLite',
                    sybase:     'Sybase'
                },
                'Web servers' => {
                    apache: 'Apache',
                    iis:    'IIS',
                    jetty:  'Jetty',
                    nginx:  'Nginx',
                    tomcat: 'TomCat'
                },
                'Programming languages' => {
                    asp:    'ASP',
                    aspx:   'ASP.NET',
                    jsp:    'JSP',
                    perl:   'Perl',
                    php:    'PHP',
                    python: 'Python',
                    ruby:   'Ruby'
                },
                'Frameworks' => {
                    rack: 'Rack'
                }
            }

        end
    end

    describe '#list_checks' do
        context 'when a pattern is given' do
            it 'uses it to filter out checks that do not match it' do
                @f.list_checks( 'boo' ).size == 0

                @f.list_checks( 'taint' ).should == @f.list_checks
                @f.list_checks.size == 1
            end
        end
    end

    describe '#list_plugins' do
        it 'returns info on all plugins' do
            loaded = @f.plugins.loaded
            @f.list_plugins.map { |r| r.delete( :path ); r }
                .sort_by { |e| e[:shortname] }.should == YAML.load( '
---
- :name: \'\'
  :description: \'\'
  :author:
  - Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
  :version: \'0.1\'
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
  :shortname: !binary |-
    ZGlzdHJpYnV0YWJsZQ==
- :name: \'\'
  :description: \'\'
  :author:
  - Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
  :version: \'0.1\'
  :shortname: !binary |-
    bG9vcA==
- :name: Wait
  :description: \'\'
  :tags:
  - wait_string
  - :wait_sym
  :author:
  - Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
  :version: \'0.1\'
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
  :shortname: !binary |-
    d2l0aF9vcHRpb25z
' ).sort_by { |e| e[:shortname] }
            @f.plugins.loaded.should == loaded
        end

        context 'when a pattern is given' do
            it 'uses it to filter out plugins that do not match it' do
                @f.list_plugins( 'bad|foo' ).size == 2
                @f.list_plugins( 'boo' ).size == 0
            end
        end
    end

    describe '#list_reports' do
        it 'returns info on all reports' do
            loaded = @f.reports.loaded
            @f.list_reports.map { |r| r[:options] = []; r.delete( :path ); r }
                .sort_by { |e| e[:shortname] }.should == YAML.load( '
---
- :name: Report abstract class.
  :options: []

  :description: This class should be extended by all reports.
  :author:
  - zapotek
  :version: 0.1.1
  :shortname: afr
- :name: Report abstract class.
  :options: []

  :description: This class should be extended by all reports.
  :author:
  - zapotek
  :version: 0.1.1
  :shortname: foo
').sort_by { |e| e[:shortname] }
            @f.reports.loaded.should == loaded
        end

        context 'when a pattern is given' do
            it 'uses it to filter out reports that do not match it' do
                @f.list_reports( 'foo' ).size == 1
                @f.list_reports( 'boo' ).size == 0
            end
        end
    end

end
