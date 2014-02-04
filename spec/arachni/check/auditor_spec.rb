require 'spec_helper'

class AuditorTest < Arachni::Check::Base
    include Arachni::Check::Auditor

    self.shortname = Factory[:issue_data][:check][:shortname]

    def initialize( framework )
        @framework = framework
        load_page_from @framework.opts.url
        framework.trainer.page = page

        http.update_cookies( page.cookiejar )
    end

    def load_page_from( url )
        @page = Arachni::Page.from_url( url )
    end

    def self.info
        check_info = Factory[:issue_data][:check].dup

        # Should be calculated by the auditor when it logs the issue.
        check_info.delete :shortname

        check_info[:issue] = {
            name:            "Check name \xE2\x9C\x93",
            description:     'Issue description',
            references:      {
                'Title' => 'http://some/url'
            },
            cwe:             1,
            severity:        Arachni::Severity::HIGH,
            remedy_guidance: 'How to fix the issue.',
            remedy_code:     'Sample code on how to fix the issue',
            tags:            %w(these are a few tags)
        }
        check_info
    end
end

describe Arachni::Check::Auditor do

    before :each do
        @opts = Arachni::Options.instance
        @opts.audit.elements :links, :forms, :cookies, :headers

        @opts.url = web_server_url_for( :auditor )
        @url      = @opts.url.dup

        @framework = Arachni::Framework.new( @opts )
        @auditor   = AuditorTest.new( @framework )
    end

    after :each do
        @framework.clean_up
        @framework.reset

        if ::EM.reactor_running?
            ::EM.stop
            sleep 0.1 while ::EM.reactor_running?
        end
    end

    let(:issue) { Factory[:issue] }
    let(:issue_data) { Factory[:issue_data].tap { |d| d.delete :check } }

    describe '#register_results' do
        it 'registers issues with the framework' do
            @auditor.register_results( [ Factory[:issue] ] )
            @framework.checks.results.first.should == Factory[:issue]
        end
    end

    describe '#create_issue' do
        it 'creates an issue' do
            @auditor.class.create_issue( vector: issue.vector ).should == issue
        end
    end

    describe '#log_issue' do
        it 'logs an issue' do
            @auditor.log_issue( issue_data )

            logged_issue = @framework.checks.results.first
            logged_issue.to_h.should == issue.to_h.merge( referring_page: {
                body: @auditor.page.body,
                dom:  @auditor.page.dom.to_h
            })
        end

        it 'assigns a #referring_page' do
            @auditor.log_issue( issue_data )

            logged_issue = @framework.checks.results.first
            logged_issue.referring_page.should == @auditor.page
        end
    end

    describe '#log' do
        it 'preserves the given remarks' do
            @auditor.log( issue_data )

            logged_issue = @framework.checks.results.first
            logged_issue.remarks.first.should be_any
        end

        context 'when given a page' do
            after { @framework.http.run }

            it 'includes response data' do
                @auditor.log( issue_data )
                @framework.checks.results.first.response.should ==
                    issue_data[:page].response
            end

            it 'includes request data' do
                @auditor.log( issue_data )
                @framework.checks.results.first.request.should ==
                    issue_data[:page].request
            end
        end

        context 'when not given a page' do
            it 'uses the current page' do
                issue_data.delete(:page)
                @auditor.log( issue_data )

                @framework.checks.results.first.page.body.should ==
                    @auditor.page.body
                @framework.checks.results.first.response.should ==
                    @auditor.page.response
                @framework.checks.results.first.request.should ==
                    @auditor.page.request
            end
        end
    end

    describe '#audit' do
        before do
            @seed = 'my_seed'
            @default_input_value = 'blah'
            issues.clear
            Arachni::Element::Capabilities::Auditable.reset
         end

        context 'when called with no opts' do
            it 'uses the defaults' do
                @auditor.load_page_from( @url + '/link' )
                @auditor.audit( @seed )
                @framework.http.run
                @framework.checks.results.size.should == 1
            end
        end

        context 'when the payloads are per platform' do
            it 'assigns the platform of the payload to the issue' do
                @auditor.load_page_from( @url + '/link' )
                @auditor.audit( { unix: @seed }, substring: @seed )
                @framework.http.run
                @framework.checks.results.size.should == 1
                issue = @framework.checks.results.first
                issue.platform_name.should == :unix
                issue.platform_type.should == :os
            end
        end

        context 'when called with opts' do
            describe :elements do

                before { @auditor.load_page_from( @url + '/elem_combo' ) }

                describe 'Arachni::Element::Link' do
                    it 'audits links' do
                        @auditor.audit( @seed,
                            format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                            elements: [ Arachni::Element::Link ]
                         )
                        @framework.http.run
                        @framework.checks.results.size.should == 1
                        issue = @framework.checks.results.first
                        issue.vector.class.should == Arachni::Element::Link
                        issue.vector.affected_input_name.should == 'link_input'
                    end
                end
                describe 'Arachni::Element::Form' do
                    it 'audits forms' do
                        @auditor.audit( @seed,
                            format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                            elements: [ Arachni::Element::Form ]
                         )
                        @framework.http.run
                        @framework.checks.results.size.should == 1
                        issue = @framework.checks.results.first
                        issue.vector.class.should == Arachni::Element::Form
                        issue.vector.affected_input_name.should == 'form_input'
                    end
                end
                describe 'Arachni::Element::Cookie' do
                    it 'audits cookies' do
                        @auditor.audit( @seed,
                            format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                            elements: [ Arachni::Element::Cookie ]
                         )
                        @framework.http.run
                        @framework.checks.results.size.should == 1
                        issue = @framework.checks.results.first
                        issue.vector.class.should == Arachni::Element::Cookie
                        issue.vector.affected_input_name.should == 'cookie_input'
                    end
                    it 'maintains the session while auditing cookies' do
                        @auditor.load_page_from( @url + '/session' )
                        @auditor.audit( @seed,
                                        format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                        elements: [ Arachni::Element::Cookie ]
                        )
                        @framework.http.run
                        @framework.checks.results.size.should == 1
                        issue = @framework.checks.results.first
                        issue.vector.class.should == Arachni::Element::Cookie
                        issue.vector.affected_input_name.should == 'vulnerable'
                    end

                end
                describe 'Arachni::Element::Header' do
                    it 'audits headers' do
                        @auditor.audit( @seed,
                            format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                            elements: [ Arachni::Element::Header ]
                         )
                        @framework.http.run
                        @framework.checks.results.size.should == 1
                        issue = @framework.checks.results.first
                        issue.vector.class.should == Arachni::Element::Header
                        issue.vector.affected_input_name.should == 'Referer'
                    end
                end

                context 'when using default options' do
                    it 'audits all element types' do
                        @auditor.audit( @seed,
                            format: [ Arachni::Check::Auditor::Format::STRAIGHT ]
                         )
                        @framework.http.run
                        @framework.checks.results.size.should == 4
                    end
                end
            end

            describe :train do
                context 'default' do
                    it 'parses the responses of forms submitted with their default values and feed any new elements back to the framework to be audited' do
                        # page feedback queue
                        pages = [ Arachni::Page.from_url( @url + '/train/default' ) ]

                        # initial page
                        @framework.trainer.page = pages.first

                        # feed the new pages/elements back to the queue
                        @framework.trainer.on_new_page { |p| pages << p }

                        # audit until no more new elements appear
                        while (page = pages.pop)
                            auditor = Auditor.new( page, @framework )
                            auditor.audit( @seed )
                            # run audit requests
                            @framework.http.run
                        end

                        issue = @framework.checks.results.first
                        issue.should be_true
                        issue.vector.class.should == Arachni::Element::Link
                        issue.vector.affected_input_name.should == 'you_made_it'
                    end
                end

                context true do
                    it 'parses all responses and feed any new elements back to the framework to be audited' do
                        # page feedback queue
                        pages = [ Arachni::Page.from_url( @url + '/train/true' ) ]

                        # initial page
                        @framework.trainer.page = pages.first

                        # feed the new pages/elements back to the queue
                        @framework.trainer.on_new_page { |p| pages << p }

                        # audit until no more new elements appear
                        while page = pages.pop
                            auditor = Arachni::Check::Base.new( page, @framework )
                            auditor.audit( @seed, train: true )
                            # run audit requests
                            @framework.http.run
                        end

                        issue = issues.first
                        issue.should be_true
                        issue.vector.class.should == Arachni::Element::Form
                        issue.vector.affected_input_name.should == 'you_made_it'
                    end
                end

                context false do
                    it 'skips analysis' do
                        # page feedback queue
                        page = Arachni::Page.from_url( @url + '/train/true' )

                        # initial page
                        @framework.trainer.page = page

                        updated_pages = []
                        # feed the new pages/elements back to the queue
                        @framework.trainer.on_new_page { |p| updated_pages << p }

                        auditor = Arachni::Check::Base.new( page, @framework )
                        auditor.audit( @seed, train: false )
                        @framework.http.run
                        updated_pages.should be_empty
                    end
                end
            end
        end
    end

    describe '#trace_taint' do
        context 'when tracing the data-flow' do
            let(:taint) { Arachni::Utilities.generate_token }
            let(:url) do
                Arachni::Utilities.normalize_url( web_server_url_for( :taint_tracer ) ) +
                    "/data_trace/global-functions?taint=#{taint}"
            end

            context 'and the resource is a' do
                context String do
                    it 'loads the URL and traces the taint' do
                        pages = []
                        @auditor.trace_taint( url, taint: taint ) do |page|
                            pages << page
                            false
                        end
                        @auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_data_flow_check_pages  pages
                    end
                end

                context Arachni::HTTP::Response do
                    it 'loads it and traces the taint' do
                        pages = []

                        @auditor.trace_taint( Arachni::HTTP::Client.get( url, mode: :sync ),
                                              taint: taint ) do |page|
                            pages << page
                            false
                        end
                        @auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_data_flow_check_pages  pages
                    end
                end

                context Arachni::Page do
                    it 'loads it and traces the taint' do
                        pages = []

                        @auditor.trace_taint( Arachni::Page.from_url( url ),
                                              taint: taint ) do |page|
                            pages << page
                            false
                        end
                        @auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_data_flow_check_pages  pages
                    end
                end
            end

            context 'and requires a custom taint injector' do
                let(:injector) { "location.hash = #{taint.inspect}" }
                let(:url) do
                    Arachni::Utilities.normalize_url( web_server_url_for( :taint_tracer ) ) +
                        'needs-injector'
                end

                context 'and the resource is a' do
                    context String do
                        it 'loads the URL and traces the taint' do
                            pages = []
                            @auditor.trace_taint( url,
                                                  taint: taint,
                                                  injector: injector ) do |page|
                                pages << page
                                false
                            end
                            @auditor.browser_cluster.wait

                            browser_cluster_job_taint_tracer_data_flow_with_injector_check_pages  pages
                        end
                    end

                    context Arachni::HTTP::Response do
                        it 'loads it and traces the taint' do
                            pages = []
                            @auditor.trace_taint( Arachni::HTTP::Client.get( url, mode: :sync ),
                                                  taint: taint,
                                                  injector: injector ) do |page|
                                pages << page
                                false
                            end
                            @auditor.browser_cluster.wait

                            browser_cluster_job_taint_tracer_data_flow_with_injector_check_pages  pages
                        end
                    end

                    context Arachni::Page do
                        it 'loads it and traces the taint' do
                            pages = []
                            @auditor.trace_taint( Arachni::Page.from_url( url ),
                                                  taint: taint,
                                                  injector: injector ) do |page|
                                pages << page
                                false
                            end
                            @auditor.browser_cluster.wait

                            browser_cluster_job_taint_tracer_data_flow_with_injector_check_pages  pages
                        end
                    end
                end
            end
        end

        context 'when tracing the execution-flow' do
            let(:url) do
                Arachni::Utilities.normalize_url( web_server_url_for( :taint_tracer ) ) +
                    "debug?input=_#{@auditor.browser_cluster.javascript_token}TaintTracer.log_execution_flow_sink()"
            end

            context 'and the resource is a' do
                context String do
                    it 'loads the URL and traces the taint' do
                        pages = []
                        @auditor.trace_taint( url ) do |page|
                            pages << page
                            false
                        end
                        @auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_execution_flow_check_pages pages
                    end
                end

                context Arachni::HTTP::Response do
                    it 'loads it and traces the taint' do
                        pages = []
                        @auditor.trace_taint( Arachni::HTTP::Client.get( url, mode: :sync ) ) do |page|
                            pages << page
                            false
                        end
                        @auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_execution_flow_check_pages pages
                    end
                end

                context Arachni::Page do
                    it 'loads it and traces the taint' do
                        pages = []
                        @auditor.trace_taint( Arachni::Page.from_url( url ) ) do |page|
                            pages << page
                            false
                        end
                        @auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_execution_flow_check_pages pages
                    end
                end
            end
        end

        context 'when the block returns' do
            let(:url) { Arachni::Utilities.normalize_url( web_server_url_for( :browser )  ) + 'explore' }

            context true do
                it 'marks the job as done' do
                    calls = 0
                    @auditor.trace_taint( url ) do
                        calls += 1
                        true
                    end
                    @auditor.browser_cluster.wait
                    calls.should == 1
                end
            end

            context false do
                it 'allows the job to continue' do
                    calls = 0
                    @auditor.trace_taint( url ) do
                        calls += 1
                        false
                    end
                    @auditor.browser_cluster.wait
                    calls.should > 1
                end
            end
        end
    end
end
