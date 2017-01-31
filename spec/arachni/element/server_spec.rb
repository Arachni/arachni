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

        context 'when given an invalid URL' do
            it 'returns false' do
                expect(auditable.log_remote_file_if_exists( '433' )).to be_falsey
            end
        end

        context 'when given a valid URL' do
            it 'returns true' do
                expect(auditable.log_remote_file_if_exists( @base_url )).to be_truthy
            end
        end

        context 'when a remote file exists' do
            it 'logs an issue' do
                file = @base_url + 'true'
                auditable.log_remote_file_if_exists( file )
                @framework.http.run

                logged_issue = Arachni::Data.issues.first
                expect(logged_issue.vector.url.split( '?' ).first).to eq(file)
                expect(logged_issue.vector.class).to eq(Arachni::Element::Server)
                expect(logged_issue.check).to eq({
                    name:      'Auditor',
                    shortname: 'auditor_test'
                })
                expect(logged_issue.proof).to eq(
                    logged_issue.page.response.status_line
                )

                expect(logged_issue.name).to eq(@auditor.class.info[:issue][:name])
                expect(logged_issue.trusted).to be_truthy
            end

            it 'assigns the extra Issue options' do
                auditable.log_remote_file_if_exists( @base_url + 'true', false, trusted: false )
                @framework.http.run
                expect(Arachni::Data.issues.first).to_not be_trusted
            end

            context 'when one issue is logged' do
                it "does not push the response to the #{Arachni::Trainer}" do
                    auditable.log_remote_file_if_exists( @base_url + 'true' )

                    expect(@framework.trainer).not_to receive(:push)
                    @framework.http.run
                end
            end

            context 'when multiple issues are logged' do
                it "pushes the responses to the #{Arachni::Trainer}" do
                    auditable.log_remote_file_if_exists( @base_url + 'true' )
                    auditable.log_remote_file_if_exists( "#{url}/each_candidate_dom_element" )

                    expect(@framework.trainer).to receive(:push).twice
                    @framework.http.run
                end
            end
        end

        context 'when a remote file does not exist' do
            it 'does not log an issue' do
                auditable.log_remote_file_if_exists( @base_url + 'false' )
                @framework.http.run
                expect(Arachni::Data.issues).to be_empty
            end

            it "does not push the responses to the #{Arachni::Trainer}" do
                auditable.log_remote_file_if_exists( @base_url + 'false' )

                expect(@framework.trainer).not_to receive(:push)
                @framework.http.run
            end
        end

        context 'when issues are too similar' do
            let(:check_url) { @base_url + 'true' }

            it 'flags them as untrusted' do
                10.times { auditable.log_remote_file_if_exists( check_url ) }
                @framework.http.run

                expect(issues).to be_any
                issues.each do |issue|
                    expect(issue).to be_untrusted
                end
            end

            it 'assigns a remark' do
                10.times { auditable.log_remote_file_if_exists( check_url ) }
                @framework.http.run

                expect(issues).to be_any

                issues.each do |issue|
                    expect(issue.remarks[:meta_analysis]).to eq([described_class::REMARK])
                end
            end

            it "does not push the responses to the #{Arachni::Trainer}" do
                10.times { auditable.log_remote_file_if_exists( url ) }

                expect(@framework.trainer).not_to receive(:push)
                @framework.http.run
            end
        end
    end

    describe '#remote_file_exist?' do
        before do
            @base_url = url + '/log_remote_file_if_exists/'
        end

        context 'when given an invalid URL' do
            it 'returns false' do
                expect(auditable.remote_file_exist?( '433' )).to be_falsey
            end
        end

        context 'when given a valid URL' do
            it 'returns true' do
                expect(auditable.remote_file_exist?( @base_url )).to be_truthy
            end
        end

        context 'without a custom 404 handler' do
            it 'performs fingerprinting' do
                url = @base_url + 'true'

                # We run this twice because the cache is empty the first time
                # around so we don't know what kind of handler we're dealing with.

                auditable.remote_file_exist?( url ) {}
                @framework.http.run

                request = nil
                @framework.http.on_complete do |response|
                    next if url != response.url
                    request = response.request
                end

                auditable.remote_file_exist?( url ) {}
                @framework.http.run

                expect(request.fingerprint?).to be_truthy
            end

            context 'when a remote file exists' do
                it 'yields true' do
                    exists = false
                    auditable.remote_file_exist?( @base_url + 'true' ) { |bool| exists = bool }
                    @framework.http.run
                    expect(exists).to be_truthy
                end

                context 'on subsequent calls' do
                    it 'does not perform a check for a custom-404' do
                        auditable.remote_file_exist?( @base_url + 'true' ) {}
                        @framework.http.run

                        exists = false
                        expect(@framework.http).not_to receive(:custom_404?)
                        auditable.remote_file_exist?( @base_url + 'true' ) { |bool| exists = bool }
                        @framework.http.run
                        expect(exists).to be_truthy
                    end
                end
            end

            context 'when a remote file does not exist' do
                it 'yields false' do
                    exists = true
                    auditable.remote_file_exist?( @base_url + 'false' ) { |bool| exists = bool }
                    @framework.http.run
                    expect(exists).to be_falsey
                end
            end

            context 'when the response is a redirect' do
                context 'and the final page is found' do
                    it 'yields true' do
                        exists = true
                        auditable.remote_file_exist?( @base_url + 'redirect' ) { |bool| exists = bool }
                        @framework.http.run
                        expect(exists).to be_truthy
                    end
                end

                context 'and the final page is not found' do
                    it 'yields false' do
                        exists = true
                        auditable.remote_file_exist?( @base_url + 'redirect/not_found' ) { |bool| exists = bool }
                        @framework.http.run
                        expect(exists).to be_falsey
                    end
                end
            end
        end

        context 'with a custom 404 handler' do
            before { @_404_url = @base_url + 'custom_404/' }

            it 'does not perform fingerprinting' do
                url = @_404_url + 'true'

                # We run this twice because the cache is empty the first time
                # around so we don't know what kind of handler we're dealing with.

                auditable.remote_file_exist?( url ) {}
                @framework.http.run

                request = nil
                @framework.http.on_complete do |response|
                    next if url != response.url
                    request = response.request
                end

                auditable.remote_file_exist?( url ) {}
                @framework.http.run

                expect(request.fingerprint?).to be_falsey
            end

            context 'and the response' do
                context 'is static' do
                    it 'yields false' do
                        exists = true
                        url = @_404_url + 'static/this_does_not_exist'
                        auditable.remote_file_exist?( url ) { |bool| exists = bool }
                        @framework.http.run
                        expect(exists).to be_falsey
                    end
                end

                context 'is dynamic' do
                    context 'and contains the requested resource' do
                        it 'yields false' do
                            exists = true
                            url = @_404_url + 'invalid/this_does_not_exist'
                            auditable.remote_file_exist?( url ) { |bool| exists = bool }
                            @framework.http.run
                            expect(exists).to be_falsey
                        end
                    end

                    context 'and contains arbitrary dynamic data' do
                        it 'yields false' do
                            exists = true
                            url = @_404_url + 'dynamic/this_does_not_exist'
                            auditable.remote_file_exist?( url ) { |bool| exists = bool }
                            @framework.http.run
                            expect(exists).to be_falsey
                        end
                    end

                    context 'and contains a combination of the above' do
                        it 'yields false' do
                            exist = []
                            100.times {
                                url = @_404_url + 'combo/this_does_not_exist_' + rand( 9999 ).to_s
                                auditable.remote_file_exist?( url ) { |bool| exist << bool }
                            }
                            @framework.http.run
                            expect(exist.include?( true )).to be_falsey
                        end
                    end
                end
            end
        end
    end
end
