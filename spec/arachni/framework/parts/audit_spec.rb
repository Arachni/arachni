require 'spec_helper'

describe Arachni::Framework::Parts::Audit do
    include_examples 'framework'

    describe Arachni::OptionGroups::Scope do
        describe '#exclude_binaries' do
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
                audited.sort.should == [@url + '/binary'].sort

                audited = []
                Arachni::Framework.new do |f|
                    f.options.url = @url
                    f.options.scope.restrict_paths << @url + '/binary'
                    f.options.scope.exclude_binaries = true
                    f.checks.load :taint

                    f.on_page_audit { |p| audited << p.url }
                    f.run
                end
                audited.should be_empty
            end
        end

        describe '#extend_paths' do
            it 'extends the crawl scope' do
                Arachni::Framework.new do |f|
                    f.options.url = "#{@url}/elem_combo"
                    f.options.scope.extend_paths = %w(/some/stuff /more/stuff)
                    f.options.audit.elements :links, :forms, :cookies
                    f.checks.load :taint

                    f.run

                    f.report.sitemap.should include "#{@url}/some/stuff"
                    f.report.sitemap.should include "#{@url}/more/stuff"
                    f.report.sitemap.size.should > 3
                end
            end
        end

        describe '#restrict_paths' do
            it 'serves as a replacement to crawling' do
                Arachni::Framework.new do |f|
                    f.options.url = "#{@url}/elem_combo"
                    f.options.scope.restrict_paths = %w(/log_remote_file_if_exists/true)
                    f.options.audit.elements :links, :forms, :cookies
                    f.checks.load :taint

                    f.run

                    sitemap = f.report.sitemap.map { |u, _| u.split( '?' ).first }
                    sitemap.sort.uniq.should == f.options.scope.restrict_paths.
                        map { |p| f.to_absolute( p ) }.sort
                end
            end
        end
    end

    context 'when unable to get a response for the given URL' do
        context 'due to a network error' do
            it 'returns an empty sitemap and have failures' do
                @options.url = 'http://blahaha'
                @options.scope.restrict_paths = [@options.url]

                subject.checks.load :taint
                subject.run
                subject.failures.should be_any
            end
        end

        context 'due to a server error' do
            it 'returns an empty sitemap and have failures' do
                @options.url = @f_url + '/fail'
                @options.scope.restrict_paths = [@options.url]

                subject.checks.load :taint
                subject.run
                subject.failures.should be_any
            end
        end

        it "retries #{Arachni::Framework::AUDIT_PAGE_MAX_TRIES} times" do
            @options.url = @f_url + '/fail_4_times'
            @options.scope.restrict_paths = [@options.url]

            subject.checks.load :taint
            subject.run
            subject.failures.should be_empty
        end
    end

    describe '#http' do
        it 'provides access to the HTTP interface' do
            subject.http.is_a?( Arachni::HTTP::Client ).should be_true
        end
    end

    describe '#failures' do
        context 'when there are no failed requests' do
            it 'returns an empty array' do
                @options.url = @f_url
                @options.scope.restrict_paths = [@options.url]

                subject.checks.load :taint
                subject.run
                subject.failures.should be_empty
            end
        end
        context 'when there are failed requests' do
            it 'returns an array containing the failed URLs' do
                @options.url = @f_url + '/fail'
                @options.scope.restrict_paths = [@options.url]

                subject.checks.load :taint
                subject.run
                subject.failures.should be_any
            end
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

            Arachni::Framework.new do |f|
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

                    sleep 0.1 while f.wait_for_browser_cluster?

                    f.page_queue_total_size.should > 0
                end
            end

            it 'analyzes the DOM and pushes new paths to the url queue' do
                Arachni::Framework.new do |f|
                    f.options.url = @url
                    f.options.audit.elements :links, :forms, :cookies

                    f.url_queue_total_size.should == 0

                    f.audit_page( Arachni::Page.from_url( @url + '/with_javascript' ) )

                    f.run

                    f.url_queue_total_size.should == 3
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
                        f.run
                        f.url_queue_total_size.should == 3

                        f.reset

                        f.options.audit.elements :links, :forms, :cookies
                        f.checks.load :taint
                        f.options.scope.dom_depth_limit = 1
                        f.url_queue_total_size.should == 0

                        page = Arachni::Page.from_url( @url + '/with_javascript' )
                        page.dom.push_transition Arachni::Page::DOM::Transition.new( :page, :load )

                        f.audit_page( page ).should be_true
                        f.run
                        f.url_queue_total_size.should == 1
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

        context "when #{Arachni::Options}#platforms" do
            before do
                Arachni::Platform::Manager.reset
                subject.options.paths.fingerprinters = fixtures_path + '/empty/'
            end

            context 'have been provided' do
                context 'and are supported by the check' do
                    it 'audits it' do
                        subject.options.platforms = [:unix]
                        subject.options.audit.elements :links, :forms, :cookies

                        subject.checks.load :taint
                        subject.checks[:taint].platforms << :unix

                        subject.audit_page( Arachni::Page.from_url( @url + '/link' ) )
                        subject.report.issues.should be_any
                    end
                end

                context 'and are not supported by the check' do
                    it 'does not audit it' do
                        subject.options.platforms = [:windows]

                        subject.options.audit.elements :links, :forms, :cookies

                        subject.checks.load :taint
                        subject.checks[:taint].platforms << :unix

                        subject.audit_page( Arachni::Page.from_url( @url + '/link' ) )
                        subject.report.issues.should be_empty
                    end
                end
            end

            context 'have not been provided' do
                it 'audits it' do
                    subject.options.platforms = []
                    subject.options.audit.elements :links, :forms, :cookies

                    subject.checks.load :taint
                    subject.checks[:taint].platforms << :unix

                    subject.audit_page( Arachni::Page.from_url( @url + '/link' ) )
                    subject.report.issues.should be_any
                end
            end
        end

        context "when #{Arachni::Check::Auditor}.has_timeout_candidates?" do
            it "calls #{Arachni::Check::Auditor}.timeout_audit_run" do
                Arachni::Check::Auditor.stub(:has_timeout_candidates?){ true }

                Arachni::Check::Auditor.should receive(:timeout_audit_run)
                subject.audit_page( Arachni::Page.from_url( @url + '/link' ) )
            end
        end

        context 'when the page contains elements seen in previous pages' do
            it 'removes them from the page'
        end

        context 'when a check fails with an exception' do
            it 'moves to the next one' do
                @options.paths.checks  = fixtures_path + '/checks/'

                Arachni::Framework.new do |f|
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

end
