require 'spec_helper'

class AuditorTest < Arachni::Component::Base
    include Arachni::Check::Auditor

    self.shortname = Factory[:issue_data][:check][:shortname]

    def initialize( framework )
        @framework = framework
        load_page_from @framework.opts.url
        framework.trainer.page = page

        http.update_cookies( page.cookiejar )
    end

    def reset
        @framework.reset
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

    before :all do
        @opts = Arachni::Options.instance
        @opts.audit :links, :forms, :cookies, :headers

        @opts.url = web_server_url_for( :auditor )
        @url      = @opts.url.dup

        @framework = Arachni::Framework.new( @opts )
        @auditor   = AuditorTest.new( @framework )
    end

    after :each do
        @auditor.reset
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
            logged_issue.to_h.should == issue.to_h
        end
    end

    describe '#log' do
        context 'when given a response' do
            after { @framework.http.run }

            it 'preserves the given remarks' do
                @auditor.log( issue_data )

                logged_issue = @framework.checks.results.first
                logged_issue.remarks.first.should be_any
            end

            it 'populates and logs an issue with response data' do
                res = @framework.http.get( @opts.url.to_s, mode: :sync )
                @auditor.log( issue_data, res )

                @framework.checks.results.first.response.should == res
            end

            it 'populates and logs an issue with request data' do
                res = @framework.http.get( @opts.url.to_s, mode: :sync )
                @auditor.log( issue_data, res )

                @framework.checks.results.first.request.should == res.request
            end
        end

        context 'when it defaults to current page' do
            it 'populates and logs an issue with page response data' do
                @auditor.log( issue_data )
                @framework.checks.results.first.response.should ==
                    @auditor.page.response
            end

            it 'populates and logs an issue with page request data' do
                @auditor.log( issue_data )
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

end
