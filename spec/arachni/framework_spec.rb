require 'spec_helper'

describe Arachni::Framework do

    before( :all ) do
        @url   = web_server_url_for( :auditor )
        @f_url = web_server_url_for( :framework )

        @options = Arachni::Options.instance
    end

    before( :each ) do
        reset_options
        @options.paths.reporters = fixtures_path + '/reporters/manager_spec/'
        @options.paths.checks    = fixtures_path + '/taint_check/'

        @f = Arachni::Framework.new
        @f.options.url = @url
    end
    after( :each ) do
        File.delete( @snapshot ) rescue nil

        @f.clean_up
        @f.reset
    end

    subject { @f }

    describe '#initialize' do
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

            context 'when an exception is raised' do
                it 'raises it' do
                    expect { Arachni::Framework.new { |f| raise } }.to raise_error
                end
            end
        end
    end

    describe '#version' do
        it "returns #{Arachni::VERSION}" do
            subject.version.should == Arachni::VERSION
        end
    end

    describe '#browser_cluster' do
        it "returns #{Arachni::BrowserCluster}" do
            subject.browser_cluster.should be_kind_of Arachni::BrowserCluster
        end

        context "when #{Arachni::OptionGroups::BrowserCluster}#pool_size" do
            it 'returns nil' do
                subject.options.browser_cluster.pool_size = 0
                subject.browser_cluster.should be_nil
            end
        end

        context "when #{Arachni::OptionGroups::Scope}#dom_depth_limit" do
            it 'returns nil' do
                subject.options.scope.dom_depth_limit = 0
                subject.browser_cluster.should be_nil
            end
        end
    end

    describe '#state' do
        it "returns #{Arachni::State::Framework}" do
            subject.state.should be_kind_of Arachni::State::Framework
        end
    end

    describe '#data' do
        it "returns #{Arachni::Data::Framework}" do
            subject.data.should be_kind_of Arachni::Data::Framework
        end
    end

    describe '#on_page_audit' do
        it 'calls the given block before each page is audited' do
            ok = false
            Arachni::Framework.new do |f|
                f.options.url = @url
                f.on_page_audit { ok = true }

                f.audit_page Arachni::Page.from_url( @url + '/link' )
            end
            ok.should be_true
        end
    end

    describe '#after_page_audit' do
        it 'calls the given block before each page is audited' do
            ok = false
            Arachni::Framework.new do |f|
                f.options.url = @url
                f.after_page_audit { ok = true }

                f.audit_page Arachni::Page.from_url( @url + '/link' )
            end
            ok.should be_true
        end
    end

    context 'when unable to get a response for the given URL' do
        context 'due to a network error' do
            it 'returns an empty sitemap and have failures' do
                @options.url = 'http://blahaha'
                @options.scope.do_not_crawl

                subject.push_to_url_queue @options.url
                subject.checks.load :taint
                subject.run
                subject.failures.should be_any
            end
        end

        context 'due to a server error' do
            it 'returns an empty sitemap and have failures' do
                @options.url = @f_url + '/fail'
                @options.scope.do_not_crawl

                subject.push_to_url_queue @options.url
                subject.checks.load :taint
                subject.run
                subject.failures.should be_any
            end
        end

        it "retries #{Arachni::Framework::AUDIT_PAGE_MAX_TRIES} times" do
            @options.url = @f_url + '/fail_4_times'
            @options.scope.do_not_crawl

            subject.push_to_url_queue @options.url
            subject.checks.load :taint
            subject.run
            subject.failures.should be_empty
        end
    end

    describe '#failures' do
        context 'when there are no failed requests' do
            it 'returns an empty array' do
                @options.url = @f_url
                @options.scope.do_not_crawl

                subject.push_to_url_queue @options.url
                subject.checks.load :taint
                subject.run
                subject.failures.should be_empty
            end
        end
        context 'when there are failed requests' do
            it 'returns an array containing the failed URLs' do
                @options.url = @f_url + '/fail'
                @options.scope.do_not_crawl

                subject.push_to_url_queue @options.url
                subject.checks.load :taint
                subject.run
                subject.failures.should be_any
            end
        end
    end

    describe '#options' do
        it "provides access to #{Arachni::Options}" do
            subject.options.should be_kind_of Arachni::Options
        end

        describe "#{Arachni::OptionGroups::Scope}#exclude_binaries" do
            it 'excludes binary pages from the scan' do
                audited = []
                Arachni::Framework.new do |f|
                    f.options.url = @url
                    f.options.scope.restrict_paths << @url + '/binary'
                    f.options.audit.elements :links, :forms, :cookies
                    f.checks.load :taint

                    f.on_page_audit { |p| audited << p.url }
                    f.run
                end
                audited.sort.should == ["#{@url}/", @url + '/binary'].sort

                audited = []
                Arachni::Framework.new do |f|
                    f.options.url = @url
                    f.options.scope.restrict_paths << @url + '/binary'
                    f.options.scope.exclude_binaries = true
                    f.checks.load :taint

                    f.on_page_audit { |p| audited << p.url }
                    f.run
                end
                audited.should == ["#{@url}/"]
            end
        end

        describe "#{Arachni::OptionGroups::Scope}#restrict_paths" do
            it 'serves as a replacement to crawling' do
                Arachni::Framework.new do |f|
                    f.options.url = "#{@url}/elem_combo"
                    f.options.scope.restrict_paths = %w(/log_remote_file_if_exists/true)
                    f.options.audit.elements :links, :forms, :cookies
                    f.checks.load :taint

                    f.run

                    sitemap = f.report.sitemap.map { |u, _| u.split( '?' ).first }
                    sitemap.sort.uniq.should ==
                        [f.options.url] + f.options.scope.restrict_paths.
                            map { |p| f.to_absolute( p ) }.sort
                end
            end
        end
    end

    describe '#sitemap' do
        it 'returns a hash with covered URLs and HTTP status codes' do
            Arachni::Framework.new do |f|
                f.options.url = "#{@url}/"
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :taint

                f.run
                f.sitemap.should == { "#{@url}/" => 200 }
            end
        end
    end

    describe '#reporters' do
        it 'provides access to the reporter manager' do
            subject.reporters.is_a?( Arachni::Reporter::Manager ).should be_true
            subject.reporters.available.sort.should == %w(afr foo).sort
        end
    end

    describe '#checks' do
        it 'provides access to the check manager' do
            subject.checks.is_a?( Arachni::Check::Manager ).should be_true
            subject.checks.available.should == %w(taint)
        end
    end

    describe '#plugins' do
        it 'provides access to the plugin manager' do
            subject.plugins.is_a?( Arachni::Plugin::Manager ).should be_true
            subject.plugins.available.sort.should ==
                %w(wait bad with_options distributable loop default suspendable).sort
        end
    end

    describe '#http' do
        it 'provides access to the HTTP interface' do
            subject.http.is_a?( Arachni::HTTP::Client ).should be_true
        end
    end

    describe '#scanning?' do
        it "delegates to #{Arachni::State::Framework}#scanning?" do
            subject.state.stub(:scanning?) { :stuff }
            subject.scanning?.should == :stuff
        end
    end

    describe '#paused?' do
        it "delegates to #{Arachni::State::Framework}#paused?" do
            subject.state.stub(:paused?) { :stuff }
            subject.paused?.should == :stuff
        end
    end

    describe '#run' do
        it 'follows redirects' do
            subject.options.url = @f_url + '/redirect'
            subject.run
            subject.sitemap.should == {
                "#{@f_url}/redirect"   => 302,
                "#{@f_url}/redirected" => 200
            }
        end

        it 'performs the scan' do
            subject.options.url = @url + '/elem_combo'
            subject.options.audit.elements :links, :forms, :cookies
            subject.checks.load :taint
            subject.plugins.load :wait

            subject.run
            subject.report.issues.size.should == 3

            subject.report.plugins[:wait][:results].should == { 'stuff' => true }
        end

        it 'sets #status to scanning' do
            described_class.new do |f|
                f.options.url = @url + '/elem_combo'
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :taint

                t = Thread.new { f.run }
                Timeout.timeout( 5 ) do
                    sleep 0.1 while f.status != :scanning
                end
                t.join
            end
        end

        it 'handles heavy load' do
            @options.paths.checks  = fixtures_path + '/taint_check/'

            Arachni::Framework.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.checks.load :taint

                f.run
                f.report.issues.size.should == 500
            end
        end

        it 'handles pages with JavaScript code' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/with_javascript'
                f.options.audit.elements :links, :forms, :cookies

                f.checks.load :taint
                f.run

                f.report.issues.
                    map { |i| i.variations.first.vector.affected_input_name }.
                    uniq.sort.should == %w(link_input form_input cookie_input).sort
            end
        end

        it 'handles AJAX' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/with_ajax'
                f.options.audit.elements :links, :forms, :cookies

                f.checks.load :taint
                f.run

                f.report.issues.
                    map { |i| i.variations.first.vector.affected_input_name }.
                    uniq.sort.should == %w(link_input form_input cookie_taint).sort
            end
        end

        context 'when done' do
            it 'sets #status to :done' do
                described_class.new do |f|
                    f.options.url = @url + '/elem_combo'
                    f.options.audit.elements :links, :forms, :cookies
                    f.checks.load :taint

                    f.run
                    f.status.should == :done
                end
            end
        end

        context 'when it has log-in capabilities and gets logged out' do
            it 'logs-in again before continuing with the audit' do
                Arachni::Framework.new do |f|
                    url = web_server_url_for( :framework ) + '/'
                    f.options.url = "#{url}/congrats"

                    f.options.audit.elements :links, :forms
                    f.checks.load_all

                    f.session.configure(
                        url:    url,
                        inputs: {
                            username: 'john',
                            password: 'doe'
                        }
                    )

                    f.options.login.check_url     = url
                    f.options.login.check_pattern = 'logged-in user'

                    f.run
                    f.report.issues.size.should == 1
                end
            end
        end
    end

    describe '#abort' do
        it 'aborts the system' do
            @options.paths.checks  = fixtures_path + '/taint_check/'

            described_class.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.plugins.load :wait
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while Arachni::Data.issues.size < 2

                f.abort
                t.join

                Arachni::Data.issues.size.should < 500
            end
        end

        it 'sets #status to :aborted' do
            described_class.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end
                sleep 0.1 while f.status != :scanning

                f.abort
                f.status.should == :aborted

                t.join
                f.status.should == :aborted
            end
        end
    end

    describe '#suspend' do
        it 'suspends the system' do
            @options.paths.checks  = fixtures_path + '/taint_check/'

            described_class.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.plugins.load :wait
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while Arachni::Data.issues.size < 2

                @snapshot = f.suspend
                t.join

                Arachni::Data.issues.size.should < 500
            end

            Arachni::Snapshot.load( @snapshot ).should be_true
        end

        it 'sets #status to :suspended' do
            described_class.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end
                sleep 0.1 while f.status != :scanning

                @snapshot = f.suspend
                f.status.should == :suspended

                t.join
                f.status.should == :suspended
            end
        end

        it 'suspends plugins' do
            Arachni::Options.plugins['suspendable'] = {
                'my_option' => 'my value'
            }

            described_class.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.checks.load  :taint
                f.plugins.load :suspendable

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while f.status != :scanning

                f.suspend
                t.join

                Arachni::State.plugins.runtime[:suspendable][:data].should == 1
            end
        end

        it 'waits for the BrowserCluster jobs to finish'

        context "when #{Arachni::OptionGroups::Snapshot}#save_path" do
            context 'is a directory' do
                it 'stores the snapshot under it' do
                    @options.paths.checks       = fixtures_path + '/taint_check/'
                    @options.snapshot.save_path = Dir.tmpdir

                    described_class.new do |f|
                        f.options.url = web_server_url_for :framework_multi
                        f.options.audit.elements :links

                        f.plugins.load :wait
                        f.checks.load :taint

                        t = Thread.new do
                            f.run
                        end

                        sleep 0.1 while Arachni::Data.issues.size < 2

                        @snapshot = f.suspend
                        t.join

                        Arachni::Data.issues.size.should < 500
                    end

                    File.dirname( @snapshot ).should == Dir.tmpdir
                    Arachni::Snapshot.load( @snapshot ).should be_true
                end
            end

            context 'is a file path' do
                it 'stores the snapshot there' do
                    @options.paths.checks       = fixtures_path + '/taint_check/'
                    @options.snapshot.save_path = "#{Dir.tmpdir}/snapshot"

                    described_class.new do |f|
                        f.options.url = web_server_url_for :framework_multi
                        f.options.audit.elements :links

                        f.plugins.load :wait
                        f.checks.load :taint

                        t = Thread.new do
                            f.run
                        end

                        sleep 0.1 while Arachni::Data.issues.size < 2

                        @snapshot = f.suspend
                        t.join

                        Arachni::Data.issues.size.should < 500
                    end

                    @snapshot.should == "#{Dir.tmpdir}/snapshot"
                    Arachni::Snapshot.load( @snapshot ).should be_true
                end
            end
        end
    end

    describe '#restore' do
        it 'restores a suspended scan' do
            @options.paths.checks  = fixtures_path + '/taint_check/'

            logged_issues = 0
            described_class.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.plugins.load :wait
                f.checks.load :taint

                Arachni::Data.issues.on_new do
                    logged_issues += 1
                end

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while logged_issues < 200

                @snapshot = f.suspend
                t.join

                logged_issues.should < 500
            end

            reset_options
            @options.paths.checks  = fixtures_path + '/taint_check/'

            described_class.new do |f|
                f.restore @snapshot

                Arachni::Data.issues.on_new do
                    logged_issues += 1
                end
                f.run

                # logged_issues.should == 500
                Arachni::Data.issues.size.should == 500

                f.report.plugins[:wait][:results].should == { 'stuff' => true }
            end
        end

        it 'restores options' do
            options_hash = nil

            described_class.new do |f|
                f.options.url = @url + '/with_ajax'
                f.options.audit.elements :links, :forms, :cookies
                f.options.datastore.my_custom_option = 'my custom value'
                options_hash = f.options.to_h.deep_clone

                f.checks.load :taint

                t = Thread.new { f.run }

                sleep 0.1 while f.browser_cluster.done?
                @snapshot = f.suspend

                t.join
            end

            described_class.restore( @snapshot ) do |f|
                f.options.to_h.should == options_hash.merge( checks: ['taint'] )
                f.browser_job_skip_states.should be_any
            end
        end

        it 'restores BrowserCluster skip states' do
            described_class.new do |f|
                f.options.url = @url + '/with_ajax'
                f.options.audit.elements :links, :forms, :cookies

                f.checks.load :taint

                t = Thread.new { f.run }

                sleep 0.1 while f.browser_cluster.done?
                @snapshot = f.suspend

                t.join
            end

            described_class.restore( @snapshot ) do |f|
                f.browser_job_skip_states.should be_any
            end
        end

        it 'restores loaded checks' do
            described_class.new do |f|
                f.options.url = @url
                f.checks.load :taint

                t = Thread.new { f.run }
                sleep 0.1 while f.status != :scanning

                @snapshot = f.suspend

                t.join
            end

            described_class.restore( @snapshot ) do |f|
                f.checks.loaded.should == ['taint']
            end
        end

        it 'restores loaded plugins' do
            described_class.new do |f|
                f.options.url = @url
                f.plugins.load :wait

                t = Thread.new { f.run }
               sleep 0.1 while f.status != :scanning

                @snapshot = f.suspend
                t.join
            end

            described_class.restore( @snapshot ) do |f|
                f.plugins.loaded.should == ['wait']
            end
        end

        it 'restores plugin states' do
            Arachni::Options.plugins['suspendable'] = {
                'my_option' => 'my value'
            }

            described_class.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.checks.load  :taint
                f.plugins.load :suspendable

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while f.status != :scanning

                @snapshot = f.suspend
                t.join

                Arachni::State.plugins.runtime[:suspendable][:data].should == 1
            end

            described_class.restore( @snapshot ) do |f|
                t = Thread.new do
                    f.run
                end

                sleep 0.1 while f.status != :scanning

                f.plugins.jobs[:suspendable][:instance].counter.should == 2

                t.kill
            end
        end
    end

    describe '#pause' do
        it 'pauses the system' do
            described_class.new do |f|
                f.options.url = @url + '/elem_combo'
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end

                f.pause

                sleep 10

                f.running?.should be_true
                t.kill
            end
        end

        it 'returns an Integer request ID' do
            described_class.new do |f|
                f.options.url = @url + '/elem_combo'
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end

                f.pause.should be_kind_of Integer

                sleep 10

                f.running?.should be_true
                t.kill
            end
        end

        it 'sets #status to :paused' do
            described_class.new do |f|
                f.options.url = @url + '/elem_combo'
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end
                sleep 0.1 while f.status != :scanning

                f.pause
                f.status.should == :paused

                t.kill
            end
        end
    end

    describe '#resume' do
        it 'resumes the system' do
            described_class.new do |f|
                f.options.url = @url + '/elem_combo'
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end

                id = f.pause

                sleep 10

                f.running?.should be_true
                f.resume id
                t.join
            end
        end

        it 'sets #status to scanning' do
            described_class.new do |f|
                f.options.url = @url + '/elem_combo'
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end

                id = f.pause
                f.status.should == :paused

                f.resume id
                Timeout.timeout( 5 ) do
                    sleep 0.1 while f.status != :scanning
                end
                t.join
            end
        end
    end

    describe '#clean_up' do
        it 'stops the #plugins' do
            described_class.new do |f|
                f.options.url = @url + '/elem_combo'
                f.plugins.load :wait

                f.plugins.run
                f.clean_up
                f.plugins.jobs.should be_empty
            end
        end

        it 'sets the status to cleanup' do
            described_class.new do |f|
                f.options.url = @url + '/elem_combo'

                f.clean_up
                f.status.should == :cleanup
            end
        end

        it 'clears the page queue' do
            described_class.new do |f|
                f.options.url = @url + '/elem_combo'
                f.push_to_page_queue Arachni::Page.from_url( f.options.url )

                f.data.page_queue.should_not be_empty
                f.clean_up
                f.data.page_queue.should be_empty
            end
        end

        it 'clears the URL queue' do
            described_class.new do |f|
                f.options.url = @url + '/elem_combo'
                f.push_to_url_queue f.options.url

                f.data.url_queue.should_not be_empty
                f.clean_up
                f.data.url_queue.should be_empty
            end
        end

        it 'sets #running? to false' do
            described_class.new do |f|
                f.options.url = @url + '/elem_combo'
                f.clean_up
                f.should_not be_running
            end
        end
    end

    describe '#report_as' do
        before( :each ) do
            reset_options
            @new_framework = Arachni::Framework.new
        end

        context 'when passed a valid reporter name' do
            it 'returns the reporter as a string' do
                json = @new_framework.report_as( :json )
                JSON.load( json )['issues'].size.should == @new_framework.report.issues.size
            end

            context 'which does not support the \'outfile\' option' do
                it 'raises Arachni::Component::Options::Error::Invalid' do
                    expect { @new_framework.report_as( :stdout ) }.to raise_error Arachni::Component::Options::Error::Invalid
                end
            end
        end

        context 'when passed an invalid reporter name' do
            it 'raises Arachni::Component::Error::NotFound' do
                expect { @new_framework.report_as( :blah ) }.to raise_error Arachni::Component::Error::NotFound
            end
        end
    end

    describe '#audit_page' do
        it 'updates the #sitemap with the DOM URL' do
            subject.options.audit.elements :links, :forms, :cookies
            subject.checks.load :taint

            subject.sitemap.should be_empty

            page = Arachni::Page.from_url( @url + '/link' )
            page.dom.url = @url + '/link/#/stuff'

            subject.audit_page page
            subject.sitemap.should include @url + '/link/#/stuff'
        end

        it "runs #{Arachni::Check::Manager}#without_platforms before #{Arachni::Check::Manager}#with_platforms" do
            @options.paths.checks  = fixtures_path + '/checks/'

            described_class.new do |f|
                f.checks.load_all

                page = Arachni::Page.from_url( @url + '/link' )

                responses = []
                f.http.on_complete do |response|
                    responses << response.url
                end

                f.audit_page page

                responses.should ==
                    %w(http://localhost/test3 http://localhost/test
                        http://localhost/test2)
            end
        end

        context 'when checks were' do
            context 'ran against the page' do
                it 'returns true' do
                    subject.checks.load :taint
                    subject.audit_page( Arachni::Page.from_url( @url + '/link' ) ).should be_true
                end
            end

            context 'not ran against the page' do
                it 'returns false' do
                    subject.audit_page( Arachni::Page.from_url( @url + '/link' ) ).should be_false
                end
            end
        end

        context 'when the page contains JavaScript code' do
            it 'analyzes the DOM and pushes new pages to the page queue' do
                Arachni::Framework.new do |f|
                    f.options.audit.elements :links, :forms, :cookies
                    f.checks.load :taint

                    f.page_queue_total_size.should == 0

                    f.audit_page( Arachni::Page.from_url( @url + '/with_javascript' ) )

                    sleep 0.1 while f.wait_for_browser?

                    f.page_queue_total_size.should > 0
                end
            end

            it 'analyzes the DOM and pushes new paths to the url queue' do
                Arachni::Framework.new do |f|
                    f.options.url = @url
                    f.options.audit.elements :links, :forms, :cookies
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
                        f.options.url = @url

                        f.options.audit.elements :links, :forms, :cookies
                        f.checks.load :taint
                        f.options.scope.dom_depth_limit = 1
                        f.url_queue_total_size.should == 0
                        f.audit_page( Arachni::Page.from_url( @url + '/with_javascript' ) ).should be_true
                        sleep 0.1 while f.wait_for_browser?
                        f.url_queue_total_size.should == 2

                        f.reset

                        f.options.audit.elements :links, :forms, :cookies
                        f.checks.load :taint
                        f.options.scope.dom_depth_limit = 1
                        f.url_queue_total_size.should == 0

                        page = Arachni::Page.from_url( @url + '/with_javascript' )
                        page.dom.push_transition Arachni::Page::DOM::Transition.new( :page, :load )

                        f.audit_page( page ).should be_true
                        sleep 0.1 while f.wait_for_browser?
                        f.url_queue_total_size.should == 0
                    end
                end

                it 'returns false' do
                    page = Arachni::Page.from_data(
                        url:         @url,
                        dom:         {
                            transitions: [
                                 { page: :load },
                                 { "<a href='javascript:click();'>" => :click },
                                 { "<button dblclick='javascript:doubleClick();'>" => :ondblclick }
                             ].map { |t| Arachni::Page::DOM::Transition.new *t.first }
                        }
                    )

                    Arachni::Framework.new do |f|
                        f.checks.load :taint

                        f.options.scope.dom_depth_limit = 10
                        f.audit_page( page ).should be_true

                        f.options.scope.dom_depth_limit = 2
                        f.audit_page( page ).should be_false
                    end
                end
            end
        end

        context 'when the page matches exclusion criteria' do
            it 'does not audit it' do
                subject.options.scope.exclude_path_patterns << /link/
                subject.options.audit.elements :links, :forms, :cookies

                subject.checks.load :taint

                subject.audit_page( Arachni::Page.from_url( @url + '/link' ) )
                subject.report.issues.size.should == 0
            end

            it 'returns false' do
                subject.options.scope.exclude_path_patterns << /link/
                subject.audit_page( Arachni::Page.from_url( @url + '/link' ) ).should be_false
            end
        end

        context "when #{Arachni::Check::Auditor}.has_timeout_candidates?" do
            it "calls #{Arachni::Check::Auditor}.timeout_audit_run" do
                Arachni::Check::Auditor.stub(:has_timeout_candidates?){ true }

                Arachni::Check::Auditor.should receive(:timeout_audit_run)
                subject.audit_page( Arachni::Page.from_url( @url + '/link' ) )
            end
        end

        context 'when a check fails with an exception' do
            it 'moves to the next one' do
                @options.paths.checks  = fixtures_path + '/checks/'

                described_class.new do |f|
                    f.checks.load_all

                    f.checks[:test].any_instance.stub(:run) { raise }

                    page = Arachni::Page.from_url( @url + '/link' )

                    responses = []
                    f.http.on_complete do |response|
                        responses << response.url
                    end

                    f.audit_page page

                    responses.should == %w(http://localhost/test3 http://localhost/test2)
                end
            end
        end
    end

    describe '#page_limit_reached?' do
        context "when the #{Arachni::OptionGroups::Scope}#page_limit has" do
            context 'been reached' do
                it 'returns true' do
                    Arachni::Framework.new do |f|
                        f.options.url = web_server_url_for :framework_multi
                        f.options.audit.elements :links
                        f.options.scope.page_limit = 10

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
                        f.options.url = web_server_url_for :framework
                        f.options.audit.elements :links
                        f.options.scope.page_limit = 100

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
                        f.options.url = web_server_url_for :framework
                        f.options.audit.elements :links

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
        let(:page) { Arachni::Page.from_url( @url + '/train/true' ) }

        it 'pushes it to the page audit queue and returns true' do
            page = Arachni::Page.from_url( @url + '/train/true' )

            subject.options.audit.elements :links, :forms, :cookies
            subject.checks.load :taint

            subject.page_queue_total_size.should == 0
            subject.push_to_page_queue( page ).should be_true
            subject.run

            subject.report.issues.size.should == 1
            subject.page_queue_total_size.should > 0
        end

        it 'updates the #sitemap with the DOM URL' do
            subject.options.audit.elements :links, :forms, :cookies
            subject.checks.load :taint

            subject.sitemap.should be_empty

            page = Arachni::Page.from_url( @url + '/link' )
            page.dom.url = @url + '/link/#/stuff'

            subject.push_to_page_queue page
            subject.sitemap.should include @url + '/link/#/stuff'
        end

        it "passes it to #{Arachni::ElementFilter}#update_from_page_cache" do
            page = Arachni::Page.from_url( @url + '/link' )

            Arachni::ElementFilter.should receive(:update_from_page_cache).with(page)

            subject.push_to_page_queue page
        end

        context 'when the page has already been seen' do
            it 'ignores it' do
                page = Arachni::Page.from_url( @url + '/stuff' )

                subject.page_queue_total_size.should == 0
                subject.push_to_page_queue( page )
                subject.push_to_page_queue( page )
                subject.push_to_page_queue( page )
                subject.page_queue_total_size.should == 1
            end

            it 'returns false' do
                page = Arachni::Page.from_url( @url + '/stuff' )

                subject.page_queue_total_size.should == 0
                subject.push_to_page_queue( page ).should be_true
                subject.push_to_page_queue( page ).should be_false
                subject.push_to_page_queue( page ).should be_false
                subject.page_queue_total_size.should == 1
            end
        end

        context 'when #page_limit_reached?' do
            context true do
                it 'returns false' do
                    subject.stub(:page_limit_reached?) { true }
                    subject.push_to_page_queue( page ).should be_false
                end
            end

            context false do
                it 'returns true' do
                    subject.stub(:page_limit_reached?) { false }
                    subject.push_to_page_queue( page ).should be_true
                end
            end
        end

        context "when #{Arachni::Page::Scope}#out? is true" do
            it 'returns false' do
                Arachni::Page::Scope.any_instance.stub(:out?) { true }
                subject.push_to_page_queue( page ).should be_false
            end
        end

        context "when #{Arachni::URI::Scope}#redundant? is true" do
            it 'returns false' do
                Arachni::Page::Scope.any_instance.stub(:redundant?) { true }
                subject.push_to_page_queue( page ).should be_false
            end
        end

        context "when #{Arachni::Page::Scope}#auto_redundant? is true" do
            it 'returns false' do
                Arachni::Page::Scope.any_instance.stub(:auto_redundant?) { true }
                subject.push_to_page_queue( page ).should be_false
            end
        end

    end

    describe '#push_to_url_queue' do
        it 'pushes a URL to the URL audit queue' do
            subject.options.audit.elements :links, :forms, :cookies
            subject.checks.load :taint

            subject.url_queue_total_size.should == 0
            subject.push_to_url_queue(  @url + '/link' ).should be_true
            subject.run

            subject.report.issues.size.should == 1
            subject.url_queue_total_size.should == 3
        end

        context 'when the URL has already been seen' do
            it 'returns false' do
                subject.push_to_url_queue( @url + '/link' ).should be_true
                subject.push_to_url_queue( @url + '/link' ).should be_false
            end

            it 'ignores it' do
                subject.url_queue_total_size.should == 0
                subject.push_to_url_queue( @url + '/link' )
                subject.push_to_url_queue( @url + '/link' )
                subject.push_to_url_queue( @url + '/link' )
                subject.url_queue_total_size.should == 1
            end
        end

        context 'when #page_limit_reached?' do
            context true do
                it 'returns false' do
                    subject.stub(:page_limit_reached?) { true }
                    subject.push_to_url_queue( @url ).should be_false
                end
            end

            context false do
                it 'returns true' do
                    subject.stub(:page_limit_reached?) { false }
                    subject.push_to_url_queue( @url ).should be_true
                end
            end
        end

        context "when #{Arachni::URI::Scope}#out? is true" do
            it 'returns false' do
                Arachni::URI::Scope.any_instance.stub(:out?) { true }
                subject.push_to_url_queue( @url ).should be_false
            end
        end

        context "when #{Arachni::URI::Scope}#redundant? is true" do
            it 'returns false' do
                Arachni::URI::Scope.any_instance.stub(:redundant?) { true }
                subject.push_to_url_queue( @url ).should be_false
            end
        end

        context "when #{Arachni::URI::Scope}#auto_redundant? is true" do
            it 'returns false' do
                Arachni::URI::Scope.any_instance.stub(:auto_redundant?) { true }
                subject.push_to_url_queue( @url ).should be_false
            end
        end
    end

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        it 'includes http statistics' do
            statistics[:http].should == subject.http.statistics
        end

        [:found_pages, :audited_pages, :current_page].each  do |k|
            it "includes #{k}" do
                statistics.should include k
            end
        end

        describe :runtime do
            context 'when the scan has been running' do
                it 'returns the runtime in seconds' do
                    subject.run
                    statistics[:runtime].should > 0
                end
            end

            context 'when no scan has been running' do
                it 'returns 0' do
                    statistics[:runtime].should == 0
                end
            end
        end
    end

    describe '#list_platforms' do
        it 'returns information about all valid platforms' do
            subject.list_platforms.should == {
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
                    sybase:     'Sybase',
                    mongodb:    'MongoDB'
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
                subject.list_checks( 'boo' ).size == 0

                subject.list_checks( 'taint' ).should == subject.list_checks
                subject.list_checks.size == 1
            end
        end
    end

    describe '#list_plugins' do
        it 'returns info on all plugins' do
            subject.list_plugins.size.should == subject.plugins.available.size

            info   = subject.list_plugins.find { |p| p[:options].any? }
            plugin = subject.plugins[info[:shortname]]

            plugin.info.each do |k, v|
                if k == :author
                    info[k].should == [v].flatten
                    next
                end

                info[k].should == v
            end

            info[:shortname].should == plugin.shortname
        end

        context 'when a pattern is given' do
            it 'uses it to filter out plugins that do not match it' do
                subject.list_plugins( 'bad|foo' ).size == 2
                subject.list_plugins( 'boo' ).size == 0
            end
        end
    end

    describe '#list_reporters' do
        it 'returns info on all reporters' do
            subject.list_reporters.size.should == subject.reporters.available.size

            info   = subject.list_reporters.find { |p| p[:options].any? }
            report = subject.reporters[info[:shortname]]

            report.info.each do |k, v|
                if k == :author
                    info[k].should == [v].flatten
                    next
                end

                info[k].should == v
            end

            info[:shortname].should == report.shortname
        end

        context 'when a pattern is given' do
            it 'uses it to filter out reporters that do not match it' do
                subject.list_reporters( 'foo' ).size == 1
                subject.list_reporters( 'boo' ).size == 0
            end
        end
    end

end
