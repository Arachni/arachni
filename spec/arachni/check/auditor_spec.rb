require 'spec_helper'

class AuditorTest < Arachni::Check::Base
    include Arachni::Check::Auditor

    self.shortname = Factory[:issue_data][:check][:shortname]

    def initialize( framework )
        @framework = framework
        load_page_from @framework.options.url
        framework.trainer.page = page

        http.update_cookies( page.cookie_jar )
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
        super
        @check_info = nil
    end
end

describe Arachni::Check::Auditor do
    before :each do
        @opts = Arachni::Options.instance
        @opts.audit.elements Arachni::Page::ELEMENTS - [:link_templates]

        @opts.url = web_server_url_for( :auditor )
        @url      = @opts.url

        @framework = Arachni::Framework.new( @opts )
        AuditorTest.clear_info_cache
    end

    after :each do
        @framework.clean_up
        @framework.reset
    end

    after :all do
        $audit_timeout_called      = nil
        $audit_differential_called = nil
        $audit_taint_called        = nil
        $audit_called              = nil
    end

    element_classes = [
        Arachni::Element::Link, Arachni::Element::Link::DOM,
        Arachni::Element::Form, Arachni::Element::Form::DOM,
        Arachni::Element::Cookie, Arachni::Element::Cookie::DOM,
        Arachni::Element::Header, Arachni::Element::LinkTemplate,
        Arachni::Element::LinkTemplate::DOM, Arachni::Element::JSON,
        Arachni::Element::XML, Arachni::Element::UIInput, Arachni::Element::UIInput::DOM,
        Arachni::Element::UIForm, Arachni::Element::UIForm::DOM
    ]

    let(:auditor) { AuditorTest.new( @framework ) }
    let(:url) { @url }
    let(:issue) { Factory[:issue] }
    let(:issue_data) { Factory[:issue_data].tap { |d| d.delete :check } }
    subject { auditor }

    describe '.has_timeout_candidates?' do
        it "delegates to #{Arachni::Element::Capabilities::Analyzable}.has_timeout_candidates?" do
            expect(Arachni::Element::Capabilities::Analyzable).to receive(:has_timeout_candidates?)
            described_class.has_timeout_candidates?
        end
    end

    describe '.timeout_audit_run' do
        it "delegates to #{Arachni::Element::Capabilities::Analyzable}.timeout_audit_run" do
            expect(Arachni::Element::Capabilities::Analyzable).to receive(:timeout_audit_run)
            described_class.timeout_audit_run
        end
    end

    describe '#preferred' do
        it 'returns an empty array' do
            expect(subject.preferred).to eq([])
        end
    end

    describe '#max_issues' do
        it 'returns the maximum amount of issues the auditor is allowed to log' do
            subject.class.info[:max_issues] = 1
            expect(subject.max_issues).to eq(1)
        end
    end

    describe '#increment_issue_counter' do
        it 'increments the issue counter' do
            i = subject.class.issue_counter
            subject.increment_issue_counter
            expect(subject.class.issue_counter).to eq(i + 1)
        end
    end

    describe '#issue_limit_reached?' do
        it 'returns false' do
            expect(subject.issue_limit_reached?).to be_falsey
        end

        context 'when the issue counter reaches the limit' do
            it 'returns true' do
                subject.class.info[:max_issues] = 1
                subject.increment_issue_counter
                expect(subject.issue_limit_reached?).to be_truthy
            end
        end
    end

    describe '#audited' do
        it 'marks the given task as audited' do
            subject.audited 'stuff'
            expect(subject.audited?( 'stuff' )).to be_truthy
        end
    end

    describe '.check?' do
        context 'when elements have been provided' do
            it 'restricts the check' do
                page = Arachni::Page.from_data( url: url, body: 'stuff',headers: [] )
                allow(page).to receive(:has_script?) { true }
                auditor.class.info[:elements] =
                    element_classes + [Arachni::Element::Body, Arachni::Element::GenericDOM]

                expect(auditor.class.check?( page, Arachni::Element::GenericDOM )).to be_truthy
                expect(auditor.class.check?( page, Arachni::Element::Body )).to be_truthy

                element_classes.each do |element|
                    expect(auditor.class.check?( page, element )).to be_falsey
                end

                expect(auditor.class.check?( page, element_classes )).to be_falsey
                expect(auditor.class.check?( page, element_classes + [Arachni::Element::Body] )).to be_truthy
            end
        end

        context 'Arachni::Element::Body' do
            before(:each) { auditor.class.info[:elements] = Arachni::Element::Body }

            context 'and page with a non-empty body' do
                it 'returns true' do
                    p = Arachni::Page.from_data( url: url, body: 'stuff' )
                    expect(auditor.class.check?( p )).to be_truthy
                end
            end

            context 'and page with an empty body' do
                it 'returns false' do
                    p = Arachni::Page.from_data( url: url, body: '' )
                    expect(auditor.class.check?( p )).to be_falsey
                end
            end
        end

        context 'Arachni::Element::GenericDOM' do
            before(:each) { auditor.class.info[:elements] = Arachni::Element::GenericDOM }
            let(:page) { Arachni::Page.from_data( url: url, body: 'stuff' ) }

            context 'and Page#has_script? is' do
                context 'true' do
                    it 'returns true' do
                        allow(page).to receive(:has_script?) { true }
                        expect(auditor.class.check?( page )).to be_truthy
                    end
                end

                context 'false' do
                    it 'returns false' do
                        allow(page).to receive(:has_script?) { false }
                        expect(auditor.class.check?( page )).to be_falsey
                    end
                end
            end
        end

        element_classes.each do |element|
            context "when #{Arachni::OptionGroups::Audit}##{element.type.to_s.gsub( '_dom', '')}? is" do
                let(:page) do
                    p = Arachni::Page.from_data(
                        url: url,
                        headers: [],
                        "#{element.type}s".gsub( '_dom', '').to_sym => [Factory[element.type]]
                    )
                    allow(p.dom).to receive(:depth) { 1 }
                    allow(p).to receive(:has_script?) { true }
                    p
                end
                before(:each) { auditor.class.info[:elements] = [element] }

                context 'true' do
                    before(:each) do
                        if element.type.to_s.start_with? 'link_template'
                            Arachni::Options.audit.link_templates =
                                Factory[element.type].template ||
                                    /input1\/(?<input1>\w+)\/input2\/(?<input2>\w+)/

                        else
                            Arachni::Options.audit.elements element.type
                        end
                    end

                    context "and the page contains #{element}" do
                        context 'and the check supports it' do
                            if element == Arachni::Element::Form::DOM ||
                                element == Arachni::Element::Cookie::DOM

                                context 'and Page::DOM#depth is' do
                                    context '0' do
                                        it 'returns false' do
                                            allow(page.dom).to receive(:depth) { 0 }
                                            expect(auditor.class.check?( page )).to be_falsey
                                        end
                                    end

                                    context '> 0' do
                                        it 'returns true' do
                                            allow(page.dom).to receive(:depth) { 1 }
                                            expect(auditor.class.check?( page )).to be_truthy
                                        end
                                    end
                                end

                                context 'and Page#has_script? is' do
                                    context 'true' do
                                        it 'returns true' do
                                            allow(page).to receive(:has_script?) { true }
                                            expect(auditor.class.check?( page )).to be_truthy
                                        end
                                    end

                                    context 'false' do
                                        it 'returns false' do
                                            allow(page).to receive(:has_script?) { false }
                                            expect(auditor.class.check?( page )).to be_falsey
                                        end
                                    end
                                end
                            elsif element == Arachni::Element::UIInput ||
                                         element == Arachni::Element::UIForm
                                it 'returns false' do
                                    expect(auditor.class.check?( page )).to be_falsey
                                end
                            else
                                it 'returns true' do
                                    expect(auditor.class.check?( page )).to be_truthy
                                end
                            end
                        end

                        (element_classes - [element]).each do |e|
                            context "and the check supports #{e}" do
                                if element == Arachni::Element::Cookie::DOM &&
                                    e == Arachni::Element::Cookie

                                    it 'returns true' do
                                        auditor.class.info[:elements] = e
                                        expect(auditor.class.check?( page )).to be_truthy
                                    end

                                elsif element == Arachni::Element::UIInput ||
                                    element == Arachni::Element::UIForm
                                    it 'returns false' do
                                        expect(auditor.class.check?( page )).to be_falsey
                                    end

                                elsif element == Arachni::Element::Cookie &&
                                        e == Arachni::Element::Cookie::DOM

                                    context 'and Page#has_script? is' do
                                        context 'true' do
                                            it 'returns true' do
                                                allow(page).to receive(:has_script?) { true }
                                                auditor.class.info[:elements] = e
                                                expect(auditor.class.check?( page )).to be_truthy
                                            end
                                        end

                                        context 'false' do
                                            it 'returns false' do
                                                allow(page).to receive(:has_script?) { false }
                                                auditor.class.info[:elements] = e
                                                expect(auditor.class.check?( page )).to be_falsey
                                            end
                                        end
                                    end

                                else
                                    if element == Arachni::Element::Form::DOM &&
                                        e == Arachni::Element::Form
                                        it 'returns true' do
                                            auditor.class.info[:elements] = e
                                            expect(auditor.class.check?( page )).to be_truthy
                                        end
                                    else
                                        it 'returns false' do
                                            auditor.class.info[:elements] = e
                                            expect(auditor.class.check?( page )).to be_falsey
                                        end
                                    end
                                end
                            end
                        end

                        [Arachni::Element::Path, Arachni::Element::Server, nil].each do |e|
                            context "and the check supports #{e ? e : 'everything'}" do
                                it 'returns true' do
                                    auditor.class.info[:elements] = e
                                    expect(auditor.class.check?( page )).to be_truthy
                                end
                            end
                        end
                    end
                end

                context 'false' do
                    before(:each) { Arachni::Options.audit.skip_elements element.type }

                    context "and the page contains #{element}" do
                        context "and the check only supports #{element}" do
                            it 'returns false' do
                                expect(auditor.class.check?( page )).to be_falsey
                            end
                        end

                        [Arachni::Element::Path, Arachni::Element::Server, nil].each do |e|
                            context "and the check supports #{e ? e : 'everything'}" do
                                it 'returns true' do
                                    auditor.class.info[:elements] = e
                                    expect(auditor.class.check?( page )).to be_truthy
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    describe '#log_remote_file_if_exists' do
        it "delegates to #{Arachni::Element::Server}#log_remote_file_if_exists" do
            sent     = [:stuff, false, { blah: '1' }]
            received = nil
            b        = proc {}

            allow_any_instance_of(Arachni::Element::Server).to receive(:log_remote_file_if_exists) { |instance, args, &block| received = [args, block]}

            expect(subject.log_remote_file_if_exists( *sent, &b )).to eq(received)
        end
    end

    describe '#match_and_log' do
        it "delegates to #{Arachni::Element::Body}#match_and_log" do
            sent     = [:stuff]
            received = nil
            b        = proc {}

            allow_any_instance_of(Arachni::Element::Body).to receive(:match_and_log) { |instance, args, &block| received = [args, block]}

            expect(subject.match_and_log( *sent, &b )).to eq(received)
        end
    end

    describe '#log_remote_file' do
        let(:page) { Arachni::Page.from_url @url }
        let(:issue) { Arachni::Data.issues.last }
        let(:vector) { Arachni::Element::Server.new( page.url ) }

        it 'assigns the extra Issue options' do
            expect(subject.log_remote_file( page, false )).to be_trusted
            expect(subject.log_remote_file( page, false, trusted: false )).to_not be_trusted
        end

        context 'given a' do
            describe Arachni::Page do
                it 'logs it' do
                    subject.log_remote_file( page )
                    expect(issue.page).to eq(page)
                    expect(issue.vector).to eq(vector)
                end
            end

            describe Arachni::HTTP::Response do
                it "logs it as a #{Arachni::Page}" do
                    subject.log_remote_file( page.response )
                    expect(issue.page).to eq(page)
                    expect(issue.vector).to eq(vector)
                end
            end
        end
    end

    describe '#each_candidate_element' do
        before(:each) do
            Arachni::Options.audit.link_templates = /link-template\/input\/(?<input>.+)/
            auditor.load_page_from "#{@url}each_candidate_element"

            auditor.page.jsons     = [Factory[:json]]
            auditor.page.xmls      = [Factory[:xml]]
            auditor.page.ui_inputs = [Factory[:ui_input]]
            auditor.page.ui_forms  = [Factory[:ui_form]]
        end

        it 'sets the auditor' do
            auditor.each_candidate_element do |element|
                expect(element.auditor).to eq(auditor)
            end
        end

        it 'provides the types of elements specified by the check' do
            auditor.class.info[:elements] = [Arachni::Link, Arachni::Form]

            elements = []
            auditor.each_candidate_element do |element|
                elements << element
            end

            expect(auditor.class.elements).to eq([Arachni::Link, Arachni::Form])
            expect(elements).to eq((auditor.page.links | auditor.page.forms).
                select { |e| e.inputs.any? })
        end

        context 'and no types are specified by the check' do
            it 'provides all types of elements but :inputs and :ui_forms'do
                auditor.class.info[:elements].clear

                expected_elements = Arachni::Page::ELEMENTS
                expected_elements.delete :ui_inputs
                expected_elements.delete :ui_forms

                elements = []
                auditor.each_candidate_element do |element|
                    elements << element
                end

                expect(elements.map { |e| "#{e.type}s".to_sym }.uniq).to eq(Arachni::Page::ELEMENTS)
                expect(elements).to eq((auditor.page.elements).
                    select { |e| e.inputs.any? })
            end
        end
    end

    describe '#each_candidate_dom_element' do
        before(:each) do
            Arachni::Options.audit.link_templates = /dom-link-template\/input\/(?<input>.+)/
            auditor.load_page_from "#{@url}each_candidate_dom_element"

            auditor.page.ui_inputs = [Factory[:ui_input]]
            auditor.page.ui_forms  = [Factory[:ui_form]]
        end

        it 'sets the auditor' do
            auditor.class.info[:elements].clear

            auditor.each_candidate_dom_element do |element|
                expect(element.auditor).to eq(auditor)
            end
        end

        it 'provides the types of elements specified by the check' do
            auditor.class.info[:elements] = [Arachni::Form::DOM]
            expect(auditor.class.elements).to eq([Arachni::Form::DOM])

            elements = []
            auditor.each_candidate_dom_element do |element|
                elements << element
            end

            expect(elements).to eq(auditor.page.forms.map(&:dom))
        end

        context 'and no types are specified by the check' do
            it 'provides all types of elements'do
                auditor.class.info[:elements].clear

                elements = []
                auditor.each_candidate_dom_element do |element|
                    elements << element
                end

                expect(elements).to eq(
                    (auditor.page.links.select { |l| l.dom } |
                        auditor.page.forms | auditor.page.cookies |
                        auditor.page.link_templates | auditor.page.ui_inputs |
                        auditor.page.ui_forms).map(&:dom)
                )
            end
        end
    end

    describe '#with_browser_cluster' do
        context 'when a browser cluster is' do
            context 'available' do
                it 'passes it to the given block' do
                    worker = nil

                    expect(auditor.with_browser_cluster do |cluster|
                        worker = cluster
                    end).to be_truthy

                    expect(worker).to eq(@framework.browser_cluster)
                end
            end
        end
    end

    describe '#with_browser' do
        context 'when a browser cluster is' do
            context 'available' do
                it 'passes a BrowserCluster::Worker to the given block' do
                    worker = nil

                    expect(auditor.with_browser do |browser|
                        worker = browser
                    end).to be_truthy
                    @framework.browser_cluster.wait

                    expect(worker).to be_kind_of Arachni::BrowserCluster::Worker
                end
            end
        end
    end

    describe '#skip?' do
        context 'when there is no Arachni::Page#element_audit_whitelist' do
            it 'returns false' do
                expect(auditor.page.element_audit_whitelist).to be_empty
                expect(auditor.skip?( auditor.page.elements.first )).to be_falsey
            end
        end

        context 'when there is Arachni::Page#element_audit_whitelist' do
            context 'and the element is in it' do
                it 'returns false' do
                    auditor.page.update_element_audit_whitelist auditor.page.elements.first
                    expect(auditor.skip?( auditor.page.elements.first )).to be_falsey
                end
            end

            context 'and the element is not in it' do
                it 'returns true' do
                    auditor.page.update_element_audit_whitelist auditor.page.elements.first
                    expect(auditor.skip?( auditor.page.elements.last )).to be_truthy
                end
            end
        end

        context 'when a we have already logged the same vector' do
            it 'returns true'
        end

        context 'when a preferred auditor has already logged the same vector' do
            it 'returns true'
        end
    end

    describe '#create_issue' do
        it 'creates an issue' do
            expect(
                auditor.class.create_issue(
                    proof: issue.proof,
                    vector: issue.vector
                )
            ).to eq(issue)
        end
    end

    describe '.log_issue' do
        it 'logs an issue' do
            auditor.class.log_issue( issue_data )

            logged_issue = Arachni::Data.issues.first

            expect(logged_issue.to_h.tap do |h|
                h[:page][:dom][:transitions].each { |t| t.delete :time }
                h[:referring_page][:dom][:transitions].each { |t| t.delete :time }
            end).to eq (issue.to_h.tap do |h|
                h[:page][:dom][:transitions].each { |t| t.delete :time }
                h[:referring_page][:dom][:transitions].each { |t| t.delete :time }
            end)
        end

        it 'assigns a #referring_page' do
            auditor.log_issue( issue_data )

            logged_issue = Arachni::Data.issues.first
            expect(logged_issue.referring_page).to eq(auditor.page)
        end

        it 'returns the issue' do
            expect(auditor.log_issue( issue_data )).to be_kind_of Arachni::Issue
        end

        context 'when #issue_limit_reached?' do
            it 'does not log the issue' do
                allow(auditor.class).to receive(:issue_limit_reached?) { true }

                expect(auditor.class.log_issue( issue_data )).to be_falsey
                expect(Arachni::Data.issues).to be_empty
            end
        end
    end

    describe '#log_issue' do
        it 'forwards options to .log_issue' do
            expect(auditor.class).to receive(:log_issue).with(
                issue_data.merge( referring_page: auditor.page )
            )
            auditor.log_issue( issue_data )
        end

        it 'assigns a #referring_page' do
            auditor.log_issue( issue_data )

            logged_issue = Arachni::Data.issues.first
            expect(logged_issue.referring_page).to eq(auditor.page)
        end
    end

    describe '.log' do
        let(:issue_data) do
            d = super()

            d[:page].response.url = @opts.url
            d.merge( page: d[:page] )

            d
        end

        it 'preserves the given remarks' do
            auditor.class.log( issue_data )

            logged_issue = Arachni::Data.issues.first
            expect(logged_issue.remarks.first).to be_any
        end

        it 'returns the issue' do
            expect(auditor.class.log( issue_data )).to be_kind_of Arachni::Issue
        end

        context 'when given a page' do
            after { @framework.http.run }

            it 'includes response data' do
                auditor.class.log( issue_data )
                expect(Arachni::Data.issues.first.response).to eq(
                    issue_data[:page].response
                )
            end

            it 'includes request data' do
                auditor.class.log( issue_data )
                expect(Arachni::Data.issues.first.request).to eq(
                    issue_data[:page].request
                )
            end
        end

        context 'when not given a page' do
            it 'uses the referring page' do
                issue_data[:referring_page].response.url = @opts.url
                auditor.class.log( issue_data )

                issue = Arachni::Data.issues.first

                expect(issue.page.body).to eq(issue_data[:referring_page].body)
                expect(issue.response).to eq(issue_data[:referring_page].response)
                expect(issue.request).to eq(issue_data[:referring_page].request)
            end
        end

        context 'when :referring page has been set' do
            it 'uses it to set the Issue#referring_page' do
                i = auditor.class.log( issue_data )
                expect(i.referring_page).to eq issue_data[:referring_page]
            end
        end

        context 'when no :referring page has been set' do
            it 'uses Element#page' do
                issue_data[:vector].page = issue_data.delete( :referring_page )

                i = auditor.class.log( issue_data )
                expect(i.referring_page).to eq issue_data[:vector].page
            end
        end

        context 'when no referring page data are available' do
            it 'raises ArgumentError' do
                expect do
                    issue_data[:vector].page    = nil
                    issue_data[:referring_page] = nil

                    auditor.class.log( issue_data )
                end.to raise_error ArgumentError
            end
        end

        context 'when no referring page data are available' do
            it 'raises ArgumentError' do
                expect do
                    issue_data[:vector].page    = nil
                    issue_data[:referring_page] = nil

                    auditor.class.log( issue_data )
                end.to raise_error ArgumentError
            end
        end

        context 'when the resource is out of scope' do
            let(:issue_data) do
                d = super()

                d[:page].response.url = 'http://stuff/'
                d.merge( page: d[:page] )

                d
            end

            it 'returns nil' do
                expect(auditor.log( issue_data )).to be_nil
            end

            it 'does not log the issue' do
                auditor.log( issue_data )
                expect(issues).to be_empty
            end

            context 'and the host includes the seed' do
                let(:issue_data) do
                    d = super()

                    d[:page].response.url = "http://#{Arachni::Utilities.random_seed}.com/"
                    d.merge( page: d[:page] )

                    d
                end

                it 'does not log the issue' do
                    auditor.log( issue_data )
                    expect(issues).to be_any
                end
            end
        end
    end

    describe '#log' do
        let(:issue_data) do
            d = super()

            d[:page].response.url = @opts.url
            d.merge( page: d[:page] )

            d
        end

        it 'forwards options to .log_issue' do
            expect(auditor.class).to receive(:log).with(
                issue_data.merge( referring_page: auditor.page )
            )
            auditor.log( issue_data )
        end
    end

    describe '#audit' do
        before do
            @seed = 'my_seed'
            @default_input_value = 'blah'
            issues.clear
            Arachni::Element::Capabilities::Auditable.reset
         end

        context 'when called with no options' do
            it 'uses the defaults' do
                auditor.load_page_from( @url + '/link' )
                auditor.audit( @seed )
                @framework.http.run
                expect(Arachni::Data.issues.size).to eq(1)
            end
        end

        context 'when the payloads are per platform' do
            it 'assigns the platform of the payload to the issue' do
                auditor.load_page_from( @url + '/link' )
                auditor.audit( { unix: @seed }, substring: @seed )
                @framework.http.run
                expect(Arachni::Data.issues.size).to eq(1)
                issue = Arachni::Data.issues.first
                expect(issue.platform_name).to eq(:unix)
                expect(issue.platform_type).to eq(:os)
            end
        end

        context 'when called with a block' do
            it "delegates to #{Arachni::Element::Capabilities::Auditable}#audit" do
                auditor.load_page_from( @url + '/link' )

                $audit_called = []
                auditor.page.elements.each do |element|
                    element.class.class_eval do
                        def audit( *args, &block )
                            $audit_called << self.class if $audit_called
                            super( *args, &block )
                        end
                    end
                end

                auditor.audit( @seed ){}
                expect($audit_called).to eq(auditor.class.elements)
            end
        end

        context 'when called without a block' do
            it 'delegates to #audit_signature' do
                opts = { stuff: :here }

                expect(auditor).to receive(:audit_signature).with( @seed, opts )
                auditor.audit( @seed, opts )
            end
        end

        context 'when called with options' do
            describe ':train' do
                context 'default' do
                    it 'parses the responses of forms submitted with their default values and feed any new elements back to the framework to be audited' do
                        # page feedback queue
                        pages = [ Arachni::Page.from_url( @url + '/train/default' ) ]

                        # initial page
                        @framework.trainer.page = pages.first

                        # feed the new pages/elements back to the queue
                        @framework.trainer.on_new_page { |p| pages << p }

                        vector = nil
                        # audit until no more new elements appear
                        while (page = pages.pop)
                            auditor = Auditor.new( page, @framework )
                            auditor.audit( @seed ) do |response, mutation|
                                next if !response.body.include? @seed
                                vector = mutation.affected_input_name
                            end
                            # run audit requests
                            @framework.http.run
                        end

                        expect(vector).to eq 'you_made_it'
                    end
                end

                context 'true' do
                    it 'parses all responses and feed any new elements back to the framework to be audited' do
                        # page feedback queue
                        pages = [ Arachni::Page.from_url( @url + '/train/true' ) ]

                        # initial page
                        @framework.trainer.page = pages.first

                        # feed the new pages/elements back to the queue
                        @framework.trainer.on_new_page { |p| pages << p }

                        vector = nil
                        # audit until no more new elements appear
                        while (page = pages.pop)
                            auditor = Arachni::Check::Base.new( page, @framework )
                            auditor.audit( @seed, submit: { train: true } ) do |response, mutation|
                                next if !response.body.include?( @seed ) ||
                                    mutation.affected_input_name != 'you_made_it'

                                vector = mutation.affected_input_name
                            end
                            # run audit requests
                            @framework.http.run
                        end

                        expect(vector).to eq 'you_made_it'
                    end
                end

                context 'false' do
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
                        expect(updated_pages).to be_empty
                    end
                end
            end
        end
    end

    describe '#audit_signature' do
        it "delegates to #{Arachni::Element::Capabilities::Analyzable::Signature}#signature_analysis" do
            auditor.load_page_from( @url + '/link' )

            $audit_signature_called = []
            auditor.page.elements.each do |element|
                element.class.class_eval do
                    def signature_analysis( *args, &block )
                        $audit_signature_called << self.class if $audit_signature_called
                        super( *args, &block )
                    end
                end
            end

            auditor.audit_signature( 'seed' )
            expect($audit_signature_called).to eq(auditor.class.elements)
        end
    end

    describe '#audit_differential' do
        it "delegates to #{Arachni::Element::Capabilities::Analyzable::Differential}#differential_analysis" do
            auditor.load_page_from( @url + '/link' )

            $audit_differential_called = []
            auditor.page.elements.each do |element|
                element.class.class_eval do
                    def differential_analysis( *args, &block )
                        $audit_differential_called << self.class if $audit_differential_called
                        super( *args, &block )
                    end
                end
            end

            auditor.audit_differential( { false: '0', pairs: { '1' => '2' } } )
            expect($audit_differential_called).to eq(auditor.class.elements)
        end
    end

    describe '#audit_timeout' do
        it "delegates to #{Arachni::Element::Capabilities::Analyzable::Timeout}#timeout_analysis" do
            auditor.load_page_from( @url + '/link' )

            $audit_timeout_called = []
            auditor.page.elements.each do |element|
                element.class.class_eval do
                    def timeout_analysis( *args, &block )
                        $audit_timeout_called << self.class if $audit_timeout_called
                        super( *args, &block )
                    end
                end
            end

            auditor.audit_timeout( 'seed', timeout: 1 )
            expect($audit_timeout_called).to eq(auditor.class.elements)
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
                context 'String' do
                    it 'loads the URL and traces the taint' do
                        pages = []
                        auditor.trace_taint( url, taint: taint ) do |page|
                            pages << page
                            false
                        end
                        auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_data_flow_check_pages  pages
                    end
                end

                context 'Arachni::HTTP::Response' do
                    it 'loads it and traces the taint' do
                        pages = []

                        auditor.trace_taint( Arachni::HTTP::Client.get( url, mode: :sync ),
                                              taint: taint ) do |page|
                            pages << page
                            false
                        end
                        auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_data_flow_check_pages  pages
                    end
                end

                context 'Arachni::Page' do
                    it 'loads it and traces the taint' do
                        pages = []

                        auditor.trace_taint( Arachni::Page.from_url( url ),
                                              taint: taint ) do |page|
                            pages << page
                            false
                        end
                        auditor.browser_cluster.wait

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
                    context 'String' do
                        it 'loads the URL and traces the taint' do
                            pages = []
                            auditor.trace_taint( url,
                                                  taint: taint,
                                                  injector: injector ) do |page|
                                pages << page
                                false
                            end
                            auditor.browser_cluster.wait

                            browser_cluster_job_taint_tracer_data_flow_with_injector_check_pages  pages
                        end
                    end

                    context 'Arachni::HTTP::Response' do
                        it 'loads it and traces the taint' do
                            pages = []
                            auditor.trace_taint( Arachni::HTTP::Client.get( url, mode: :sync ),
                                                  taint: taint,
                                                  injector: injector ) do |page|
                                pages << page
                                false
                            end
                            auditor.browser_cluster.wait

                            browser_cluster_job_taint_tracer_data_flow_with_injector_check_pages  pages
                        end
                    end

                    context 'Arachni::Page' do
                        it 'loads it and traces the taint' do
                            pages = []
                            auditor.trace_taint( Arachni::Page.from_url( url ),
                                                  taint: taint,
                                                  injector: injector ) do |page|
                                pages << page
                                false
                            end
                            auditor.browser_cluster.wait

                            browser_cluster_job_taint_tracer_data_flow_with_injector_check_pages  pages
                        end
                    end
                end
            end
        end

        context 'when tracing the execution-flow' do
            let(:url) do
                Arachni::Utilities.normalize_url( web_server_url_for( :taint_tracer ) ) +
                    "debug?input=_#{auditor.browser_cluster.javascript_token}TaintTracer.log_execution_flow_sink()"
            end

            context 'and the resource is a' do
                context 'String' do
                    it 'loads the URL and traces the taint' do
                        pages = []
                        auditor.trace_taint( url ) do |page|
                            pages << page
                            false
                        end
                        auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_execution_flow_check_pages pages
                    end
                end

                context 'Arachni::HTTP::Response' do
                    it 'loads it and traces the taint' do
                        pages = []
                        auditor.trace_taint( Arachni::HTTP::Client.get( url, mode: :sync ) ) do |page|
                            pages << page
                            false
                        end
                        auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_execution_flow_check_pages pages
                    end
                end

                context 'Arachni::Page' do
                    it 'loads it and traces the taint' do
                        pages = []
                        auditor.trace_taint( Arachni::Page.from_url( url ) ) do |page|
                            pages << page
                            false
                        end
                        auditor.browser_cluster.wait

                        browser_cluster_job_taint_tracer_execution_flow_check_pages pages
                    end
                end
            end
        end

        context 'when the block returns' do
            let(:url) { Arachni::Utilities.normalize_url( web_server_url_for( :browser )  ) + 'explore' }

            context 'true' do
                it 'marks the job as done' do
                    pending

                    calls = 0
                    auditor.trace_taint( url ) do
                        calls += 1
                        true
                    end
                    auditor.browser_cluster.wait
                    expect(calls).to eq(1)
                end
            end

            context 'false' do
                it 'allows the job to continue' do
                    calls = 0
                    auditor.trace_taint( url ) do
                        calls += 1
                        false
                    end
                    auditor.browser_cluster.wait
                    expect(calls).to be > 1
                end
            end
        end
    end
end
