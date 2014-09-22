require 'spec_helper'

describe Arachni::OptionGroups::Paths do

    after do
        IO.write( "#{subject.root}.logdir", '' )
    end

    %w(root arachni components logs checks reporters plugins services
        path_extractors fingerprinters lib support mixins snapshots).each do |method|

        describe "##{method}" do
            it 'points to an existing directory' do
                File.exists?( subject.send method ).should be_true
            end
        end

        it { should respond_to method }
        it { should respond_to "#{method}=" }
    end

    describe '#logs' do
        context 'when the ARACHNI_FRAMEWORK_LOGDIR environment variable' do
            context 'has been set' do
                it 'returns its value' do
                    ENV['ARACHNI_FRAMEWORK_LOGDIR'] = 'test'
                    subject.logs.should == 'test/'
                end
            end
            context 'has not been set' do
                it 'returns the default location' do
                    ENV['ARACHNI_FRAMEWORK_LOGDIR'] = nil
                    subject.logs.should == "#{subject.root}logs/"
                end
            end
        end

        context 'when .logdir' do
            context 'has been set' do
                it 'returns its value' do
                    IO.write( "#{subject.root}.logdir", 'stuff' )

                    described_class.new.logs.should == 'stuff/'
                end
            end

            context 'has not been set' do
                it 'returns the default location' do
                    subject.logs.should == "#{subject.root}logs/"
                end
            end
        end
    end

end
