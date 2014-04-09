require 'spec_helper'

describe Arachni::Options do
    before( :each ) do
        @utils = Arachni::Utilities
    end

    subject { reset_options; described_class.instance }

    it 'proxies missing class methods to instance methods' do
        url = 'http://test.com/'
        subject.url.should_not == url
        subject.url = url
        subject.url.should == url
    end

    %w(checks platforms plugins authorized_by no_fingerprinting spawns).each do |method|
        it { should respond_to method }
        it { should respond_to "#{method}=" }
    end

    %w(audit datastore dispatcher http login output paths rpc scope).each do |group|
        describe "##{group}" do
            it 'is an OptionGroup' do
                subject.send( group ).should be_kind_of Arachni::OptionGroup
                subject.send( group ).class.to_s.downcase.should ==
                    "arachni::optiongroups::#{group}"
            end
        end
    end

    describe '#spawns' do
        it 'defaults to 0' do
            subject.spawns.should == 0
        end

        it 'converts its argument to Integer' do
            subject.spawns = '5'
            subject.spawns.should == 5
        end
    end

    describe '#do_not_fingerprint' do
        it 'disables fingerprinting' do
            subject.no_fingerprinting.should be_false
            subject.do_not_fingerprint
            subject.no_fingerprinting.should be_true
        end
    end

    describe '#fingerprint' do
        it 'enables fingerprinting' do
            subject.do_not_fingerprint
            subject.no_fingerprinting.should be_true

            subject.fingerprint
            subject.no_fingerprinting.should be_false
        end
    end

    describe '#fingerprint?' do
        context 'when fingerprinting is enabled' do
            it 'returns true' do
                subject.no_fingerprinting = false
                subject.fingerprint?.should be_true
            end
        end

        context 'when fingerprinting is disabled' do
            it 'returns false' do
                subject.no_fingerprinting = true
                subject.fingerprint?.should be_false
            end
        end
    end

    describe '#validate' do
        context 'when valid' do
            it 'returns nil' do
                subject.validate.should be_empty
            end
        end

        context 'when invalid' do
            it 'returns errors by group' do
                subject.login.check_pattern = /test/
                subject.validate.should == {
                    login: {
                        check_url: "Option is missing."
                    }
                }
            end
        end
    end

    describe '#url=' do
        it 'normalizes its argument' do
            subject.url = 'http://test.com/my path'
            subject.url.should == @utils.normalize_url( subject.url )
        end

        it 'accepts the HTTP scheme' do
            subject.url = 'http://test.com'
            subject.url.should == 'http://test.com/'
        end

        it 'accepts the HTTPS scheme' do
            subject.url = 'https://test.com'
            subject.url.should == 'https://test.com/'
        end

        context 'when passed reserved host' do
            %w(localhost 127.0.0.1).each do |hostname|
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
    end

    describe '#update' do
        it 'sets options by hash' do
            opts = { url: 'http://blah2.com' }

            subject.update( opts )
            subject.url.to_s.should == @utils.normalize_url( opts[:url] )
        end

        context 'when key refers to an OptionGroup' do
            it 'updates that group' do
                opts = {
                    scope: {
                        exclude_path_patterns:   [ 'exclude me2' ],
                        include_path_patterns:   [ 'include me2' ],
                        redundant_path_patterns: { 'redundant' => 4 },
                    },
                    datastore: {
                        key2: 'val2'
                    }
                }

                subject.update( opts )

                subject.scope.exclude_path_patterns.should == [/exclude me2/]
                subject.scope.include_path_patterns.should == [/include me2/]
                subject.scope.redundant_path_patterns.should == { /redundant/ => 4 }
                subject.datastore.to_h.should == opts[:datastore]
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
            raised.should be_false
        end
    end

    describe '#load' do
        it 'loads a file created by #save' do
            f = "#{Dir.tmpdir}/options"

            subject.scope.restrict_paths = 'test'
            subject.save( f )

            options = subject.load( f )
            options.should == subject
            options.scope.restrict_paths.should == ['test']

            raised = false
            begin
                File.delete( f )
            rescue
                raised = true
            end
            raised.should be_false
        end
    end

    describe '#to_hash' do
        it 'converts self to a hash' do
            subject.scope.restrict_paths = 'test'
            subject.checks << 'stuff'
            subject.datastore.stuff      = 'test2'

            h = subject.to_hash
            h.should be_kind_of Hash

            h.each do |k, v|
                next if k == :instance
                subject_value = subject.send(k)

                case v
                    when nil
                        v.should be_nil

                    when Array
                        subject_value.should == v

                    else
                        (subject_value.respond_to?( :to_h ) ? subject_value.to_h : v).should == v
                end
            end
        end
    end

    describe '#to_h' do
        it 'aliased to to_hash' do
            subject.to_hash.should == subject.to_h
        end
    end

end
