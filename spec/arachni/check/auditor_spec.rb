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
        return @check_info if @check_info
        @check_info = Factory[:issue_data][:check].dup

        # Should be calculated by the auditor when it logs the issue.
        @check_info.delete :shortname

        @check_info[:issue] = {
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
        @check_info
    end

    def self.clear_info_cache
        @check_info = nil
    end
end

describe Arachni::Check::Auditor do
    before :each do
        @opts = Arachni::Options.instance
        @opts.audit.elements :links, :forms, :cookies, :headers

        @opts.url = web_server_url_for( :auditor )
        @url      = @opts.url

        @framework = Arachni::Framework.new( @opts )

        AuditorTest.clear_info_cache
        @auditor   = AuditorTest.new( @framework )
    end

    after :each do
        @framework.clean_up
        @framework.reset
    end

    let(:auditor) { @auditor }
    let(:url) { @url }
    let(:issue) { Factory[:issue] }
    let(:issue_data) { Factory[:issue_data].tap { |d| d.delete :check } }

    describe '.check?' do
        [Arachni::Element::Body, Arachni::Element::GenericDOM].each do |element|
            context element do
                before(:each) { auditor.class.info[:elements] = element }

                context 'and page with a non-empty body' do
                    it 'returns true' do
                        p = Arachni::Page.from_data( url: url, body: 'stuff' )
                        auditor.class.check?( p ).should be_true
                    end
                end

                context 'and page with an empty body' do
                    it 'returns false' do
                        p = Arachni::Page.from_data( url: url, body: '' )
                        auditor.class.check?( p ).should be_false
                    end
                end
            end
        end

        element_classes = [Arachni::Element::Link, Arachni::Element::Link::DOM,
                           Arachni::Element::Form, Arachni::Element::Form::DOM,
                           Arachni::Element::Cookie, Arachni::Element::Header ]

        element_classes.each do |element|
            context "when #{Arachni::OptionGroups::Audit}##{element.type.to_s.gsub( '_dom', '')}? is" do
                let(:page) do
                    Arachni::Page.from_data(
                        url: url,
                        "#{element.type}s".gsub( '_dom', '').to_sym => [Factory[element.type]]
                    )
                end
                before(:each) { auditor.class.info[:elements] = [element] }

                context true do
                    before(:each) { Arachni::Options.audit.elements element.type }

                    context "and the page contains #{element}" do
                        context 'and the check supports it' do
                            it 'returns true' do
                                auditor.class.check?( page ).should be_true
                            end
                        end

                        (element_classes - [element]).each do |e|
                            context "and the check supports #{e}" do
                                if element == Arachni::Element::Form::DOM &&
                                    e == Arachni::Element::Form
                                    it 'returns true' do
                                        auditor.class.info[:elements] = e
                                        auditor.class.check?( page ).should be_true
                                    end
                                else
                                    it 'returns false' do
                                        auditor.class.info[:elements] = e
                                        auditor.class.check?( page ).should be_false
                                    end
                                end
                            end
                        end

                        [Arachni::Element::Path, Arachni::Element::Server, nil].each do |e|
                            context "and the check supports #{e ? e : 'everything'}" do
                                it 'returns true' do
                                    auditor.class.info[:elements] = e
                                    auditor.class.check?( page ).should be_true
                                end
                            end
                        end
                    end
                end

                context false do
                    before(:each) { Arachni::Options.audit.skip_elements element.type }

                    context "and the page contains #{element}" do
                        context "and the check only supports #{element}" do
                            it 'returns false' do
                                auditor.class.check?( page ).should be_false
                            end
                        end

                        [Arachni::Element::Path, Arachni::Element::Server, nil].each do |e|
                            context "and the check supports #{e ? e : 'everything'}" do
                                it 'returns true' do
                                    auditor.class.info[:elements] = e
                                    auditor.class.check?( page ).should be_true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    describe '#each_candidate_element' do
        before(:each) { auditor.load_page_from "#{@url}each_candidate_element" }

        it 'sets the auditor' do
            auditor.each_candidate_element do |element|
                element.auditor.should == auditor
            end
        end

        context 'when types have been provided' do
            it 'provides those types of elements' do
                elements = []
                auditor.each_candidate_element [ Arachni::Link, Arachni::Header ] do |element|
                    elements << element
                end

                elements.should == auditor.page.links | auditor.page.headers
            end

            context 'and are not supported' do
                it 'raises ArgumentError' do
                    expect {
                        auditor.each_candidate_element [Arachni::Link::DOM]
                    }.to raise_error ArgumentError
                end
            end
        end
        context 'when types have not been provided' do
            it 'provides the types of elements specified by the check' do
                elements = []
                auditor.each_candidate_element do |element|
                    elements << element
                end

                auditor.class.elements.should == [Arachni::Link, Arachni::Form]
                elements.should == auditor.page.links | auditor.page.forms
            end

            context 'and no types are specified by the check' do
                it 'provides all types of elements'do
                    auditor.class.info[:elements].clear

                    elements = []
                    auditor.each_candidate_element do |element|
                        elements << element
                    end

                    elements.should == auditor.page.elements
                end
            end
        end
    end

    describe '#each_candidate_dom_element' do
        before(:each) { auditor.load_page_from "#{@url}each_candidate_dom_element" }

        it 'sets the auditor' do
            auditor.each_candidate_element do |element|
                element.auditor.should == auditor
            end
        end

        context 'when types have been provided' do
            it 'provides those types of elements' do
                elements = []
                auditor.each_candidate_dom_element [ Arachni::Link::DOM ] do |element|
                    elements << element
                end

                elements.should be_any
                elements.should == auditor.page.links.select { |l| l.dom }
            end

            context 'and are not supported' do
                it 'raises ArgumentError' do
                    expect {
                        auditor.each_candidate_dom_element [Arachni::Link]
                    }.to raise_error ArgumentError
                end
            end
        end
        context 'when types have not been provided' do
            it 'provides the types of elements specified by the check' do
                auditor.class.info[:elements] = [Arachni::Form::DOM]
                auditor.class.elements.should == [Arachni::Form::DOM]

                elements = []
                auditor.each_candidate_dom_element do |element|
                    elements << element
                end

                elements.should == auditor.page.forms
            end

            context 'and no types are specified by the check' do
                it 'provides all types of elements'do
                    auditor.class.info[:elements].clear

                    elements = []
                    auditor.each_candidate_dom_element do |element|
                        elements << element
                    end

                    elements.should ==
                        auditor.page.links.select { |l| l.dom } | auditor.page.forms
                end
            end
        end
    end

    describe '#with_browser_cluster' do
        context 'when a browser cluster is' do
            context 'available' do
                it 'passes it to the given block' do
                    worker = nil

                    @auditor.with_browser_cluster do |cluster|
                        worker = cluster
                    end.should be_true

                    worker.should == @framework.browser_cluster
                end
            end
        end
    end

    describe '#with_browser' do
        context 'when a browser cluster is' do
            context 'available' do
                it 'passes a BrowserCluster::Worker to the given block' do
                    worker = nil

                    @auditor.with_browser do |browser|
                        worker = browser
                    end.should be_true
                    @framework.browser_cluster.wait

                    worker.should be_kind_of Arachni::BrowserCluster::Worker
                end
            end
        end
    end

    describe '#skip?' do
        context 'when there is no Arachni::Page#element_audit_whitelist' do
            it 'returns false' do
                @auditor.page.element_audit_whitelist.should be_empty
                @auditor.skip?( @auditor.page.elements.first ).should be_false
            end
        end

        context 'when there is Arachni::Page#element_audit_whitelist' do
            context 'and the element is in it' do
                it 'returns false' do
                    @auditor.page.update_element_audit_whitelist @auditor.page.elements.first
                    @auditor.skip?( @auditor.page.elements.first ).should be_false
                end
            end

            context 'and the element is not in it' do
                it 'returns true' do
                    @auditor.page.update_element_audit_whitelist @auditor.page.elements.first
                    @auditor.skip?( @auditor.page.elements.last ).should be_true
                end
            end
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

            logged_issue = Arachni::State.issues.flatten.first

            logged_issue.to_h.tap do |h|
                h[:page][:dom][:transitions].first.delete :time
            end.should eq issue.to_h.merge( referring_page: {
                body: @auditor.page.body,
                dom:  @auditor.page.dom.to_h.tap do |h|
                    h.delete :skip_states
                end
            }).tap { |h| h[:page][:dom][:transitions].first.delete :time }
        end

        it 'assigns a #referring_page' do
            @auditor.log_issue( issue_data )

            logged_issue = Arachni::State.issues.flatten.first
            logged_issue.referring_page.should == @auditor.page
        end

        it 'returns the issue' do
            @auditor.log_issue( issue_data ).should be_kind_of Arachni::Issue
        end
    end

    describe '#log' do
        it 'preserves the given remarks' do
            @auditor.log( issue_data )

            logged_issue = Arachni::State.issues.flatten.first
            logged_issue.remarks.first.should be_any
        end

        it 'returns the issue' do
            @auditor.log( issue_data ).should be_kind_of Arachni::Issue
        end

        context 'when given a page' do
            after { @framework.http.run }

            it 'includes response data' do
                @auditor.log( issue_data )
                Arachni::State.issues.flatten.first.response.should ==
                    issue_data[:page].response
            end

            it 'includes request data' do
                @auditor.log( issue_data )
                Arachni::State.issues.flatten.first.request.should ==
                    issue_data[:page].request
            end
        end

        context 'when not given a page' do
            it 'uses the current page' do
                issue_data.delete(:page)
                @auditor.log( issue_data )

                issue = Arachni::State.issues.flatten.first
                issue.page.body.should == @auditor.page.body
                issue.response.should == @auditor.page.response
                issue.request.should == @auditor.page.request
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
                Arachni::State.issues.size.should == 1
            end
        end

        context 'when the payloads are per platform' do
            it 'assigns the platform of the payload to the issue' do
                @auditor.load_page_from( @url + '/link' )
                @auditor.audit( { unix: @seed }, substring: @seed )
                @framework.http.run
                Arachni::State.issues.size.should == 1
                issue = Arachni::State.issues.flatten.first
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
                        Arachni::State.issues.size.should == 1
                        issue = Arachni::State.issues.flatten.first
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
                        Arachni::State.issues.size.should == 1
                        issue = Arachni::State.issues.flatten.first
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
                        Arachni::State.issues.size.should == 1
                        issue = Arachni::State.issues.flatten.first
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
                        Arachni::State.issues.size.should == 1
                        issue = Arachni::State.issues.flatten.first
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
                        Arachni::State.issues.size.should == 1
                        issue = Arachni::State.issues.flatten.first
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
                        Arachni::State.issues.size.should == 4
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

                        Arachni::State.issues.flatten.find do |i|
                            i.vector.affected_input_name == 'you_made_it'
                        end.should be_true
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
                            auditor.audit( @seed, submit: { train: true })
                            # run audit requests
                            @framework.http.run
                        end

                        issue = issues.flatten.first
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
                        auditor.audit( @seed, submit: { train: false } )
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
                    "/data_trace/user-defined-global-functions?taint=#{taint}"
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
