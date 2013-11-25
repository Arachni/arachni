require 'spec_helper'

class AuditorTest
    include Arachni::Check::Auditor

    def initialize( framework )
        @framework = framework
        load_page_from @framework.opts.url
        framework.trainer.page = page
        mute
    end

    def reset
        @framework.reset
    end

    def http
        @framework.http
    end

    def framework
        @framework
    end

    def load_page_from( url )
        @page = Arachni::Page.from_url( url )
    end

    def self.info
        {
            name:  'Test auditor',
            issue: { name: 'Test issue' }
        }
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

    describe '#register_results' do
        it 'registers issues with the framework' do
            issue = Arachni::Issue.new( name: 'Test issue', url: @url )
            @auditor.register_results( [ issue ] )

            logged_issue = @framework.checks.results.first
            logged_issue.should be_true

            logged_issue.name.should == issue.name
            logged_issue.url.should  == issue.url
        end
    end

    describe '#log_remote_file_if_exists' do
        before do
            @base_url = @url + 'log_remote_file_if_exists/'
        end

        context 'when a remote file exists' do
            it 'logs an issue ' do
                file = @base_url + 'true'
                @auditor.log_remote_file_if_exists( file )
                @framework.http.run

                logged_issue = @framework.checks.results.first
                logged_issue.should be_true

                logged_issue.url.split( '?' ).first.should == file
                logged_issue.elem.should == Arachni::Element::PATH
                logged_issue.id.should == 'true'
                logged_issue.injected.should == 'true'
                logged_issue.mod_name.should == @auditor.class.info[:name]
                logged_issue.name.should == @auditor.class.info[:issue][:name]
                logged_issue.verification.should be_false
            end
        end

        context 'when a remote file does not exist' do
            it 'does not log an issue' do
                @auditor.log_remote_file_if_exists( @base_url + 'false' )
                @framework.http.run
                @framework.checks.results.should be_empty
            end
        end
    end

    describe '#remote_file_exist?' do
        before do
            @base_url = @url + '/log_remote_file_if_exists/'
        end

        context 'when a remote file exists' do
            it 'returns true' do
                exists = false
                @auditor.remote_file_exist?( @base_url + 'true' ) { |bool| exists = bool }
                @framework.http.run
                exists.should be_true
            end
        end

        context 'when a remote file does not exist' do
            it 'returns false' do
                exists = true
                @auditor.remote_file_exist?( @base_url + 'false' ) { |bool| exists = bool }
                @framework.http.run
                exists.should be_false
            end
        end

        context 'when the response is a redirect' do
            it 'returns false' do
                exists = true
                @auditor.remote_file_exist?( @base_url + 'redirect' ) { |bool| exists = bool }
                @framework.http.run
                exists.should be_false
            end
        end

        context 'when faced with a custom 404' do
            before { @_404_url = @base_url + 'custom_404/' }

            context 'and the response' do
                context 'is static' do
                    it 'returns false' do
                        exists = true
                        url = @_404_url + 'static/this_does_not_exist'
                        @auditor.remote_file_exist?( url ) { |bool| exists = bool }
                        @framework.http.run
                        exists.should be_false
                    end
                end

                context 'is dynamic' do
                    context 'and contains the requested resource' do
                        it 'returns false' do
                            exists = true
                            url = @_404_url + 'invalid/this_does_not_exist'
                            @auditor.remote_file_exist?( url ) { |bool| exists = bool }
                            @framework.http.run
                            exists.should be_false
                        end
                    end

                    context 'and contains arbitrary dynamic data' do
                        it 'returns false' do
                            exists = true
                            url = @_404_url + 'dynamic/this_does_not_exist'
                            @auditor.remote_file_exist?( url ) { |bool| exists = bool }
                            @framework.http.run
                            exists.should be_false
                        end
                    end

                    context 'and contains a combination of the above' do
                        it 'returns false' do
                            exist = []
                            100.times {
                                url = @_404_url + 'combo/this_does_not_exist_' + rand( 9999 ).to_s
                                @auditor.remote_file_exist?( url ) { |bool| exist << bool }
                            }
                            @framework.http.run
                            exist.include?( true ).should be_false
                        end
                    end
                end
            end

        end
    end

    describe '#log_remote_file' do
        it 'logs a remote file' do
            file = @url + 'log_remote_file_if_exists/true'
            @framework.http.get( file ).on_complete { |res| @auditor.log_remote_file( res ) }
            @framework.http.run

            logged_issue = @framework.checks.results.first
            logged_issue.should be_true

            logged_issue.url.split( '?' ).first.should == file
            logged_issue.elem.should == Arachni::Element::PATH
            logged_issue.id.should == 'true'
            logged_issue.injected.should == 'true'
            logged_issue.mod_name.should == @auditor.class.info[:name]
            logged_issue.name.should == @auditor.class.info[:issue][:name]
            logged_issue.verification.should be_false
        end
    end

    describe '#log_issue' do
        it 'logs an issue' do
            opts = { name: 'Test issue', url: @url }
            @auditor.log_issue( opts )

            logged_issue = @framework.checks.results.first
            logged_issue.name.should == opts[:name]
            logged_issue.url.should  == opts[:url]
        end
    end

    describe '#match_and_log' do
        before do
            @base_url = @url + '/match_and_log'
            @regex = {
                :valid   => /match/i,
                :invalid => /will not match/,
            }
        end

        context 'when a response' do
            after { @framework.http.run }

            context 'matches the given pattern' do
                it 'logs an issue' do
                    @framework.http.get( @base_url ).on_complete do |res|
                        regexp = @regex[:valid]
                        @auditor.match_and_log( regexp, res.body )

                        logged_issue = @framework.checks.results.first
                        logged_issue.should be_true

                        logged_issue.url.should == @opts.url.to_s
                        logged_issue.elem.should == Arachni::Element::BODY
                        logged_issue.opts[:regexp].should == regexp.to_s
                        logged_issue.opts[:match].should == 'Match'
                        logged_issue.opts[:element].should == Arachni::Element::BODY
                        logged_issue.regexp.should == regexp.to_s
                        logged_issue.verification.should be_false
                    end
                end
            end

            context 'does not match the given pattern' do
                it 'does not log an issue' do
                    @framework.http.get( @base_url ).on_complete do |res|
                        @auditor.match_and_log( @regex[:invalid], res.body )
                        @framework.checks.results.should be_empty
                    end
                end
            end
        end

        context 'when defaulting to current page' do
            context 'and it matches the given pattern' do
                it 'logs an issue' do
                    regexp = @regex[:valid]

                    @auditor.match_and_log( regexp )

                    logged_issue = @framework.checks.results.first
                    logged_issue.should be_true

                    logged_issue.url.should == @opts.url.to_s
                    logged_issue.elem.should == Arachni::Element::BODY
                    logged_issue.opts[:regexp].should == regexp.to_s
                    logged_issue.opts[:match].should == 'Match'
                    logged_issue.opts[:element].should == Arachni::Element::BODY
                    logged_issue.regexp.should == regexp.to_s
                    logged_issue.verification.should be_false
                end
            end

            context 'and it does not matche the given pattern' do
                it 'does not log an issue' do
                    @auditor.match_and_log( @regex[:invalid] )
                    @framework.checks.results.should be_empty
                end
            end
        end
    end

    describe '#log' do

        before do
            @log_opts = {
                altered:  'foo',
                injected: 'foo injected',
                id: 'foo id',
                regexp: /foo regexp/,
                match: 'foo regexp match',
                remarks: {
                    dude: ['Stuff'],
                },
                element: Arachni::Element::LINK
            }
        end


        context 'when given a response' do

            after { @framework.http.run }

            it 'preserves the given remarks' do
                @auditor.log( @log_opts )

                logged_issue = @framework.checks.results.first
                logged_issue.remarks[:dude].should be_true
            end

            it 'populates and logs an issue with response data' do
                @framework.http.get( @opts.url.to_s ).on_complete do |res|
                    @auditor.log( @log_opts, res )

                    logged_issue = @framework.checks.results.first
                    logged_issue.should be_true

                    logged_issue.url.should == res.url
                    logged_issue.elem.should == Arachni::Element::LINK
                    logged_issue.opts[:regexp].should == @log_opts[:regexp].to_s
                    logged_issue.opts[:match].should == @log_opts[:match]
                    logged_issue.opts[:element].should == Arachni::Element::LINK
                    logged_issue.regexp.should == @log_opts[:regexp].to_s
                    logged_issue.verification.should be_false
                end
            end
        end

        context 'when it defaults to current page' do
            it 'populates and logs an issue with page data' do
                @auditor.log( @log_opts )

                logged_issue = @framework.checks.results.first
                logged_issue.should be_true

                logged_issue.url.should == @auditor.page.url
                logged_issue.elem.should == Arachni::Element::LINK
                logged_issue.opts[:regexp].should == @log_opts[:regexp].to_s
                logged_issue.opts[:match].should == @log_opts[:match]
                logged_issue.opts[:element].should == Arachni::Element::LINK
                logged_issue.regexp.should == @log_opts[:regexp].to_s
                logged_issue.verification.should be_false
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
                issue.platform.should == :unix
                issue.platform_type.should == :os
            end
        end

        context 'when called with opts' do
            describe :elements do

                before { @auditor.load_page_from( @url + '/elem_combo' ) }

                describe 'Arachni::Element::LINK' do
                    it 'audits links' do
                        @auditor.audit( @seed,
                            format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                            elements: [ Arachni::Element::LINK ]
                         )
                        @framework.http.run
                        @framework.checks.results.size.should == 1
                        issue = @framework.checks.results.first
                        issue.elem.should == Arachni::Element::LINK
                        issue.var.should == 'link_input'
                    end
                end
                describe 'Arachni::Element::FORM' do
                    it 'audits forms' do
                        @auditor.audit( @seed,
                            format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                            elements: [ Arachni::Element::FORM ]
                         )
                        @framework.http.run
                        @framework.checks.results.size.should == 1
                        issue = @framework.checks.results.first
                        issue.elem.should == Arachni::Element::FORM
                        issue.var.should == 'form_input'
                    end
                end
                describe 'Arachni::Element::COOKIE' do
                    it 'audits cookies' do
                        @auditor.audit( @seed,
                            format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                            elements: [ Arachni::Element::COOKIE ]
                         )
                        @framework.http.run
                        @framework.checks.results.size.should == 1
                        issue = @framework.checks.results.first
                        issue.elem.should == Arachni::Element::COOKIE
                        issue.var.should == 'cookie_input'
                    end
                    it 'maintains the session while auditing cookies' do
                        @auditor.load_page_from( @url + '/session' )
                        @auditor.audit( @seed,
                                        format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                                        elements: [ Arachni::Element::COOKIE ]
                        )
                        @framework.http.run
                        @framework.checks.results.size.should == 1
                        issue = @framework.checks.results.first
                        issue.elem.should == Arachni::Element::COOKIE
                        issue.var.should == 'vulnerable'
                    end

                end
                describe 'Arachni::Element::HEADER' do
                    it 'audits headers' do
                        @auditor.audit( @seed,
                            format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                            elements: [ Arachni::Element::HEADER ]
                         )
                        @framework.http.run
                        @framework.checks.results.size.should == 1
                        issue = @framework.checks.results.first
                        issue.elem.should == Arachni::Element::HEADER
                        issue.var.should == 'Referer'
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
                        while page = pages.pop
                            auditor = Arachni::Check::Base.new( page, @framework )
                            auditor.audit( @seed )
                            # run audit requests
                            @framework.http.run
                        end

                        issue = @framework.checks.results.first
                        issue.should be_true
                        issue.elem.should == Arachni::Element::LINK
                        issue.var.should == 'you_made_it'
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
                        issue.elem.should == Arachni::Element::FORM
                        issue.var.should == 'you_made_it'
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
