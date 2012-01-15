require_relative '../../spec_helper'
require_from_root( 'framework' )

class AuditorTest
    include Arachni::Module::Auditor
    include Arachni::UI::Output

    def initialize( framework )
        @framework = framework
        http.trainer.set_page( page )
        mute!
    end

    def page
        @page ||= Arachni::Parser::Page.new(
            url:  @framework.opts.url.to_s,
            body: 'Match this!'
        )
    end

    def http
        @framework.http
    end

    def framework
        @framework
    end

    def self.info
        {
            :name => 'Test auditor',
            :issue => {
                :name => 'Test issue'
            }
        }
    end
end

describe Arachni::Module::Auditor do

    before :all do
        @opts = Arachni::Options.instance
        @opts.url = server_url

        @url = @opts.url.to_s + '/auditor'

        @framework = Arachni::Framework.new( @opts )
        @auditor = AuditorTest.new( @framework )
    end

    after :each do
        @framework.modules.results.clear
    end

    it 'should #register_results' do
        issue = Arachni::Issue.new( name: 'Test issue', url: @url )
        @auditor.register_results( [ issue ] )

        logged_issue = @framework.modules.results.first
        logged_issue.name.should == issue.name
        logged_issue.url.should  == issue.url
    end

    context '#log_remote_file_if_exists' do
        before do
            @base_url = @url + '/log_remote_file_if_exists/'
        end

        it 'should log issue if file exists' do
            file = @base_url + 'true'
            @auditor.log_remote_file_if_exists( file )
            @framework.http.run

            logged_issue = @framework.modules.results.first
            logged_issue.url.split( '?' ).first.should == file
            logged_issue.elem.should == Arachni::Issue::Element::PATH
            logged_issue.id.should == 'true'
            logged_issue.injected.should == 'true'
            logged_issue.mod_name.should == @auditor.class.info[:name]
            logged_issue.name.should == @auditor.class.info[:issue][:name]
            logged_issue.verification.should be_false
        end

        it 'should not log issue if file doesn\'t exist' do
            @auditor.log_remote_file_if_exists( @base_url + 'false' )
            @framework.http.run
            @framework.modules.results.should be_empty
        end
    end

    context '#remote_file_exist?' do
        before do
            @base_url = @url + '/log_remote_file_if_exists/'
        end

        after :each do
            @framework.http.run
        end

        it 'should return true if file exists' do
            @framework.http.get( @base_url + 'true' ).on_complete {
                |res|
                @auditor.remote_file_exist?( res ).should be_true
            }
        end

        it 'should return false if file doesn\'t exists' do
            @framework.http.get( @base_url + 'false' ).on_complete {
                |res|
                @auditor.remote_file_exist?( res ).should be_false
            }
        end
    end


    it 'should #log_remote_file' do
        file = @url + '/log_remote_file_if_exists/true'
        @framework.http.get( file ).on_complete {
            |res|
            @auditor.log_remote_file( res )
        }
        @framework.http.run

        logged_issue = @framework.modules.results.first
        logged_issue.url.split( '?' ).first.should == file
        logged_issue.elem.should == Arachni::Issue::Element::PATH
        logged_issue.id.should == 'true'
        logged_issue.injected.should == 'true'
        logged_issue.mod_name.should == @auditor.class.info[:name]
        logged_issue.name.should == @auditor.class.info[:issue][:name]
        logged_issue.verification.should be_false
    end

    it 'should #log_issue' do
        opts = { name: 'Test issue', url: @url }
        @auditor.log_issue( opts )

        logged_issue = @framework.modules.results.first
        logged_issue.name.should == opts[:name]
        logged_issue.url.should  == opts[:url]
    end

    context '#match_and_log' do

        before do
            @base_url = @url + '/match_and_log'
            @regex = {
                :valid   => /match/i,
                :invalid => /will not match/,
            }
        end

        context 'when given a response' do
            after do
                @framework.http.run
            end

            it 'should log issue if pattern matches' do
                @framework.http.get( @base_url ).on_complete {
                    |res|

                    regexp = @regex[:valid]

                    @auditor.match_and_log( regexp, res.body )

                    logged_issue = @framework.modules.results.first
                    logged_issue.url.should == @opts.url.to_s
                    logged_issue.elem.should == Arachni::Issue::Element::BODY
                    logged_issue.opts[:regexp].should == regexp.to_s
                    logged_issue.opts[:match].should == 'Match'
                    logged_issue.opts[:element].should == Arachni::Issue::Element::BODY
                    logged_issue.regexp.should == regexp.to_s
                    logged_issue.verification.should be_false
                }
            end

            it 'should not log issue if pattern doesn\'t match' do
                @framework.http.get( @base_url ).on_complete {
                    |res|
                    @auditor.match_and_log( @regex[:invalid], res.body )
                    @framework.modules.results.should be_empty
                }
            end
        end

        context 'when defaulting to current page' do
            it 'should log issue if pattern matches' do
                regexp = @regex[:valid]

                @auditor.match_and_log( regexp )

                logged_issue = @framework.modules.results.first
                logged_issue.url.should == @opts.url.to_s
                logged_issue.elem.should == Arachni::Issue::Element::BODY
                logged_issue.opts[:regexp].should == regexp.to_s
                logged_issue.opts[:match].should == 'Match'
                logged_issue.opts[:element].should == Arachni::Issue::Element::BODY
                logged_issue.regexp.should == regexp.to_s
                logged_issue.verification.should be_false
            end

            it 'should not log issue if pattern doesn\'t match ' do
                @auditor.match_and_log( @regex[:invalid] )
                @framework.modules.results.should be_empty
            end
        end
    end


end
