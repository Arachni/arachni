require 'spec_helper'

describe Arachni::Data::Session do
    subject { described_class.new }
    let(:plugins) { @framework.plugins }
    let(:dump_directory) do
        @dump_directory = "#{Dir.tmpdir}/session-#{Arachni::Utilities.generate_token}"
    end

    before(:each) do
        @framework = Arachni::Framework.new
        subject.clear
    end
    after(:each) do
        FileUtils.rm_rf @dump_directory if @dump_directory
        @framework.reset
    end

    describe '#statistics' do
        it 'returns an empty Hash' do
            subject.statistics.should == {}
        end
    end

    describe '#configuration' do
        it 'returns an empty Hash' do
            subject.configuration.should == {}
        end
    end

    describe '#dump' do
        it 'stores #configuration to disk' do
            subject.configuration[:stuff] = [1]
            subject.dump( dump_directory )

            results_file = "#{dump_directory}/configuration"
            File.exists?( results_file ).should be_true
            subject.configuration.should == { stuff: [1] }
        end
    end

    describe '.load' do
        it 'loads #results from disk' do
            subject.configuration[:stuff] = [1]
            subject.dump( dump_directory )

            subject.configuration.should == described_class.load( dump_directory ).configuration
        end
    end

    describe '#clear' do
        %w(configuration).each do |method|
            it "clears ##{method}" do
                subject.send(method).should receive(:clear)
                subject.clear
            end
        end
    end
end
