require 'spec_helper'

describe Arachni::Options do
    before( :each ) do
        @utils = Arachni::Utilities
    end

    subject { reset_options; described_class.instance }
    groups = [:audit, :datastore, :dispatcher, :http, :session, :output, :paths,
              :rpc, :scope, :input]

    it 'proxies missing class methods to instance methods' do
        url = 'http://test.com/'
        expect(subject.url).not_to eq(url)
        subject.url = url
        expect(subject.url).to eq(url)
    end

    %w(checks platforms plugins authorized_by no_fingerprinting spawns).each do |method|
        it { is_expected.to respond_to method }
        it { is_expected.to respond_to "#{method}=" }
    end

    groups.each do |group|
        describe "##{group}" do
            it 'is an OptionGroup' do
                expect(subject.send( group )).to be_kind_of Arachni::OptionGroup
                expect(subject.send( group ).class.to_s.downcase).to eq(
                    "arachni::optiongroups::#{group}"
                )
            end
        end
    end

    describe '#spawns' do
        it 'defaults to 0' do
            expect(subject.spawns).to eq(0)
        end

        it 'converts its argument to Integer' do
            subject.spawns = '5'
            expect(subject.spawns).to eq(5)
        end
    end

    describe '#do_not_fingerprint' do
        it 'disables fingerprinting' do
            expect(subject.no_fingerprinting).to be_falsey
            subject.do_not_fingerprint
            expect(subject.no_fingerprinting).to be_truthy
        end
    end

    describe '#fingerprint' do
        it 'enables fingerprinting' do
            subject.do_not_fingerprint
            expect(subject.no_fingerprinting).to be_truthy

            subject.fingerprint
            expect(subject.no_fingerprinting).to be_falsey
        end
    end

    describe '#fingerprint?' do
        context 'when fingerprinting is enabled' do
            it 'returns true' do
                subject.no_fingerprinting = false
                expect(subject.fingerprint?).to be_truthy
            end
        end

        context 'when fingerprinting is disabled' do
            it 'returns false' do
                subject.no_fingerprinting = true
                expect(subject.fingerprint?).to be_falsey
            end
        end
    end

    describe '#validate' do
        context 'when valid' do
            it 'returns nil' do
                expect(subject.validate).to be_empty
            end
        end

        context 'when invalid' do
            it 'returns errors by group' do
                subject.session.check_pattern = /test/
                expect(subject.validate).to eq({
                    session: {
                        check_url: "Option is missing."
                    }
                })
            end
        end
    end

    describe '#parsed_url' do
        it 'returns a parsed version of #url' do
            subject.url = 'http://test.com/'
            expect(subject.parsed_url).to eq Arachni::URI( subject.url )
        end
    end

    describe '#url=' do
        it 'normalizes its argument' do
            subject.url = 'http://test.com/my path'
            expect(subject.url).to eq(@utils.normalize_url( subject.url ))
        end

        it 'accepts the HTTP scheme' do
            subject.url = 'http://test.com'
            expect(subject.url).to eq('http://test.com/')
        end

        it 'accepts the HTTPS scheme' do
            subject.url = 'https://test.com'
            expect(subject.url).to eq('https://test.com/')
        end

        context 'when passed reserved host' do
            %w(localhost 127.0.0.1 127.0.0.2 127.1.1.1).each do |hostname|
                context hostname do
                    it "raises #{described_class::Error::ReservedHostname}" do
                        expect { subject.url = "http://#{hostname}" }.to raise_error
                            described_class::Error::ReservedHostname
                    end
                end
            end
        end

        context 'when nil is passed' do
            it "raises #{described_class::Error::InvalidURL}" do
                expect { subject.url = '/my path' }.to raise_error
                    described_class::Error::InvalidURL
            end
        end

        context 'when a relative URL is passed' do
            it "raises #{described_class::Error::InvalidURL}" do
                expect { subject.url = '/my path' }.to raise_error
                    described_class::Error::InvalidURL
            end
        end

        context 'when a URL with invalid scheme is passed' do
            it "raises #{described_class::Error::InvalidURL}" do
                expect { subject.url = 'httpss://test.com/my path' }.to raise_error
                    described_class::Error::InvalidURL
            end
        end

        context 'when a URL with no scheme is passed' do
            it "raises #{described_class::Error::InvalidURL}" do
                expect { subject.url = 'test.com/my path' }.to raise_error
                    described_class::Error::InvalidURL
            end
        end

        context "when #{Arachni::OptionGroups::Scope}#https_only?" do
            before :each do
                subject.scope.https_only = true
            end

            context 'and an HTTPS url is provided' do
                it 'accepts the HTTPS scheme' do
                    subject.url = 'https://test.com'
                    expect(subject.url).to eq('https://test.com/')
                end
            end

            context 'and an HTTP url is provided' do
                it "raises #{described_class::Error::InvalidURL}" do
                    expect do
                        subject.url = 'http://test.com/'
                    end.to raise_error described_class::Error::InvalidURL
                end
            end
        end
    end

    describe '#update' do
        it 'sets options by hash' do
            opts = { url: 'http://blah2.com' }

            subject.update( opts )
            expect(subject.url.to_s).to eq(@utils.normalize_url( opts[:url] ))
        end

        context 'when key refers to an OptionGroup' do
            it 'updates that group' do
                opts = {
                    scope: {
                        exclude_path_patterns:   [ 'exclude me2' ],
                        include_path_patterns:   [ 'include me2' ],
                        redundant_path_patterns: { 'redundant' => 4 }
                    },
                    datastore: {
                        key2: 'val2'
                    }
                }

                subject.update( opts )

                expect(subject.scope.exclude_path_patterns).to eq([/exclude me2/i])
                expect(subject.scope.include_path_patterns).to eq([/include me2/i])
                expect(subject.scope.redundant_path_patterns).to eq({ /redundant/i => 4 })
                expect(subject.datastore.to_h).to eq(opts[:datastore])
            end
        end
    end

    describe '#save' do
        it 'dumps #to_h to a file' do
            f = 'options'

            subject.save( f )

            raised = false
            begin
                File.delete( f )
            rescue
                raised = true
            end
            expect(raised).to be_falsey
        end

        it 'returns the file location'do
            f = 'options'

            f = subject.save( f )

            raised = false
            begin
                File.delete( f )
            rescue
                raised = true
            end
            expect(raised).to be_falsey
        end
    end

    describe '#load' do
        it 'loads a file created by #save' do
            f = "#{Dir.tmpdir}/options"

            subject.scope.restrict_paths = 'test'
            subject.save( f )

            options = subject.load( f )
            expect(options).to eq(subject)
            expect(options.scope.restrict_paths).to eq(['test'])

            raised = false
            begin
                File.delete( f )
            rescue
                raised = true
            end
            expect(raised).to be_falsey
        end
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }
        ignore = [:instance, :rpc, :dispatcher, :paths, :spawns, :snapshot, :output]

        it 'converts self to a serializable hash' do
            expect(data).to be_kind_of Hash

            expect(Arachni::RPC::Serializer.load(
                Arachni::RPC::Serializer.dump( data )
            )).to eq(data)
        end

        (groups - ignore).each do |k|
            k = k.to_s

            it "includes the '#{k}' group" do
                expect(data[k]).to eq(subject.send(k).to_rpc_data)
            end
        end

        ignore.each do |k|
            k = k.to_s

            it "does not include the '#{k}' group" do
                expect(subject.to_rpc_data).not_to include k
            end
        end
    end

    describe '#to_hash' do
        it 'converts self to a hash' do
            subject.scope.restrict_paths = 'test'
            subject.checks << 'stuff'
            subject.datastore.stuff      = 'test2'

            h = subject.to_hash
            expect(h).to be_kind_of Hash

            h.each do |k, v|
                next if k == :instance
                subject_value = subject.send(k)

                case v
                    when nil
                        expect(v).to be_nil

                    when Array
                        expect(subject_value).to eq(v)

                    else
                        expect(subject_value.respond_to?( :to_h ) ? subject_value.to_h : v).to eq(v)
                end
            end
        end
    end

    describe '#to_h' do
        it 'aliased to to_hash' do
            expect(subject.to_hash).to eq(subject.to_h)
        end
    end

    describe '#rpc_data_to_hash' do
        it 'normalizes the given hash into #to_hash format' do
            normalized = subject.rpc_data_to_hash(
                'http' => {
                    'request_timeout' => 90_000
                }
            )

            expect(normalized[:http][:request_timeout]).to eq(90_000)
            expect(subject.http.request_timeout).not_to eq(90_000)
        end
    end

    describe '#hash_to_rpc_data' do
        it 'normalizes the given hash into #to_rpc_data format' do
            normalized = subject.hash_to_rpc_data(
                http: { request_timeout: 90_000 }
            )

            expect(normalized['http']['request_timeout']).to eq(90_000)
            expect(subject.http.request_timeout).not_to eq(90_000)
        end
    end

end
