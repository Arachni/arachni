require 'spec_helper'

describe Arachni::Element::Server do
    it_should_behave_like 'with_auditor'

    def response
        Arachni::HTTP::Response.new(
            request: Arachni::HTTP::Request.new(
                         url:    'http://a-url.com/',
                         method: :get,
                         headers: {
                             'req-header-name' => 'req header value'
                         }
                     ),

            code:    200,
            url:     'http://a-url.com/?myvar=my%20value',
            headers: {},
            dom:     {
                transitions: [ page: :load ]
            }
        )
    end

    before :each do
        @framework ||= Arachni::Framework.new
        @auditor = Auditor.new( nil, @framework )
    end

    after :each do
        @framework.clean_up
        @framework.reset
        reset_options
    end

    subject do
        described_class.new( response.url )
    end

    let(:url) { web_server_url_for :auditor }
    let(:auditor) { @auditor }
    let(:auditable) do
        s = subject.dup
        s.auditor = auditor
        s
    end

    describe '#log_remote_file_if_exists' do
        before do
            @base_url = url + '/log_remote_file_if_exists/'
        end

        context 'when a remote file exists' do
            it 'logs an issue' do
                file = @base_url + 'true'
                auditable.log_remote_file_if_exists( file )
                @framework.http.run

                logged_issue = Arachni::Data.issues.first
                logged_issue.vector.url.split( '?' ).first.should == file
                logged_issue.vector.class.should == Arachni::Element::Server
                logged_issue.check.should == {
                    name:      'Auditor',
                    shortname: 'auditor_test'
                }
                logged_issue.name.should == @auditor.class.info[:issue][:name]
                logged_issue.trusted.should be_true
            end

            it "does not push the response to the #{Arachni::Trainer}" do
                file = @base_url + 'true'
                auditable.log_remote_file_if_exists( file )

                @framework.trainer.should_not receive(:push)
                @framework.http.run
            end
        end

        context 'when a remote file does not exist' do
            it 'does not log an issue' do
                auditable.log_remote_file_if_exists( @base_url + 'false' )
                @framework.http.run
                Arachni::Data.issues.should be_empty
            end
        end

        context 'when issues are too similar' do
            it "does not push the responses to the #{Arachni::Trainer}" do
                file = @base_url + 'true'
                10.times { auditable.log_remote_file_if_exists( file ) }

                @framework.trainer.should_not receive(:push)
                @framework.http.run
            end
        end
    end

    describe '#remote_file_exist?' do
        before do
            @base_url = url + '/log_remote_file_if_exists/'
        end

        context 'without a custom 404 handler' do
            context 'when a remote file exists' do
                it 'returns true' do
                    exists = false
                    auditable.remote_file_exist?( @base_url + 'true' ) { |bool| exists = bool }
                    @framework.http.run
                end

                context 'on subsequent calls' do
                    it 'does not perform a check for a custom-404' do
                        auditable.remote_file_exist?( @base_url + 'true' ) {}
                        @framework.http.run

                        exists = false
                        @framework.http.should_not receive(:custom_404?)
                        auditable.remote_file_exist?( @base_url + 'true' ) { |bool| exists = bool }
                        @framework.http.run
                        exists.should be_true
                    end
                end
            end

            context 'when a remote file does not exist' do
                it 'returns false' do
                    exists = true
                    auditable.remote_file_exist?( @base_url + 'false' ) { |bool| exists = bool }
                    @framework.http.run
                    exists.should be_false
                end
            end

            context 'when the response is a redirect' do
                it 'returns false' do
                    exists = true
                    auditable.remote_file_exist?( @base_url + 'redirect' ) { |bool| exists = bool }
                    @framework.http.run
                    exists.should be_false
                end
            end
        end

        context 'without a custom 404 handler' do
            before { @_404_url = @base_url + 'custom_404/' }

            context 'and the response' do
                context 'is static' do
                    it 'returns false' do
                        exists = true
                        url = @_404_url + 'static/this_does_not_exist'
                        auditable.remote_file_exist?( url ) { |bool| exists = bool }
                        @framework.http.run
                        exists.should be_false
                    end
                end

                context 'is dynamic' do
                    context 'and contains the requested resource' do
                        it 'returns false' do
                            exists = true
                            url = @_404_url + 'invalid/this_does_not_exist'
                            auditable.remote_file_exist?( url ) { |bool| exists = bool }
                            @framework.http.run
                            exists.should be_false
                        end
                    end

                    context 'and contains arbitrary dynamic data' do
                        it 'returns false' do
                            exists = true
                            url = @_404_url + 'dynamic/this_does_not_exist'
                            auditable.remote_file_exist?( url ) { |bool| exists = bool }
                            @framework.http.run
                            exists.should be_false
                        end
                    end

                    context 'and contains a combination of the above' do
                        it 'returns false' do
                            exist = []
                            100.times {
                                url = @_404_url + 'combo/this_does_not_exist_' + rand( 9999 ).to_s
                                auditable.remote_file_exist?( url ) { |bool| exist << bool }
                            }
                            @framework.http.run
                            exist.include?( true ).should be_false
                        end
                    end
                end
            end
        end
    end
end
