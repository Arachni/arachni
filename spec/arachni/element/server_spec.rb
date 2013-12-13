require 'spec_helper'

describe Arachni::Element::Server do
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
        @framework.reset if @framework
        @framework = Arachni::Framework.new
    end

    before :all do
        @auditor = Auditor.new( nil, Arachni::Framework.new )

        @server = described_class.new( response )
        @server.auditor = @auditor

        @url = web_server_url_for( :auditor )
    end

    describe '#log_remote_file_if_exists' do
        before do
            @base_url = @url + '/log_remote_file_if_exists/'
        end

        context 'when a remote file exists' do
            it 'logs an issue ' do
                file = @base_url + 'true'
                @server.log_remote_file_if_exists( file )
                @framework.http.run

                logged_issue = @framework.checks.results.first
                logged_issue.vector.url.split( '?' ).first.should == file
                logged_issue.vector.class.should == Arachni::Element::Server
                logged_issue.check.should == {
                    name:      'Auditor',
                    shortname: 'auditor_test'
                }
                logged_issue.name.should == @auditor.class.info[:issue][:name]
                logged_issue.trusted.should be_true
            end
        end

        context 'when a remote file does not exist' do
            it 'does not log an issue' do
                @server.log_remote_file_if_exists( @base_url + 'false' )
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
                @server.remote_file_exist?( @base_url + 'true' ) { |bool| exists = bool }
                @framework.http.run
                exists.should be_true
            end
        end

        context 'when a remote file does not exist' do
            it 'returns false' do
                exists = true
                @server.remote_file_exist?( @base_url + 'false' ) { |bool| exists = bool }
                @framework.http.run
                exists.should be_false
            end
        end

        context 'when the response is a redirect' do
            it 'returns false' do
                exists = true
                @server.remote_file_exist?( @base_url + 'redirect' ) { |bool| exists = bool }
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
                        @server.remote_file_exist?( url ) { |bool| exists = bool }
                        @framework.http.run
                        exists.should be_false
                    end
                end

                context 'is dynamic' do
                    context 'and contains the requested resource' do
                        it 'returns false' do
                            exists = true
                            url = @_404_url + 'invalid/this_does_not_exist'
                            @server.remote_file_exist?( url ) { |bool| exists = bool }
                            @framework.http.run
                            exists.should be_false
                        end
                    end

                    context 'and contains arbitrary dynamic data' do
                        it 'returns false' do
                            exists = true
                            url = @_404_url + 'dynamic/this_does_not_exist'
                            @server.remote_file_exist?( url ) { |bool| exists = bool }
                            @framework.http.run
                            exists.should be_false
                        end
                    end

                    context 'and contains a combination of the above' do
                        it 'returns false' do
                            exist = []
                            100.times {
                                url = @_404_url + 'combo/this_does_not_exist_' + rand( 9999 ).to_s
                                @server.remote_file_exist?( url ) { |bool| exist << bool }
                            }
                            @framework.http.run
                            exist.include?( true ).should be_false
                        end
                    end
                end
            end

        end
    end

    describe '#dup' do
        it 'duplicates self' do
            server = @server.dup
            server.should == @server
            server.object_id.should_not == @server
        end
    end

    describe '#to_h' do
        it 'returns a hash' do
            @server.to_h.should == {
                type: :server,
                url:  'http://a-url.com/?myvar=my%20value'
            }
        end
    end
end
