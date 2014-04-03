require 'spec_helper'

describe Arachni::State::Plugins do
    subject { described_class.new }
    let(:plugins) { @framework.plugins }
    let(:dump_directory) do
        @dump_directory = "#{Dir.tmpdir}/plugins-#{Arachni::Utilities.generate_token}"
    end

    before(:each) do
        @framework = Arachni::Framework.new
        subject.clear
    end
    after(:each) do
        FileUtils.rm_rf @dump_directory if @dump_directory
        @framework.reset
    end

    describe '#runtime' do
        it 'returns a Hash' do
            subject.runtime.should be_kind_of Hash
        end
    end

    describe '#statistics' do
        it 'includes plugin names' do
            plugins.load :distributable
            result = { stuff: 1 }

            subject.store( plugins.create(:distributable), result )

            subject.statistics[:names].should == [:distributable]
        end
    end

    describe '#store' do
        it 'stores plugin runtime state' do
            plugins.load :distributable
            result = { stuff: 1 }

            subject.store( plugins.create(:distributable), result )
            subject[:distributable].should == result
        end
    end

    describe '#dump' do
        it 'stores #runtime to disk' do
            subject.runtime[:distributable] = { stuff: 1 }
            subject.dump( dump_directory )

            results_file = "#{dump_directory}/runtime/distributable"
            File.exists?( results_file ).should be_true
            subject.runtime.should == {
                distributable: Marshal.load( IO.read( results_file ) )
            }
        end
    end

    describe '.load' do
        it 'loads #runtime from disk' do
            subject.runtime[:distributable] = { stuff: 1 }
            subject.dump( dump_directory )

            subject.runtime.should == described_class.load( dump_directory ).runtime
        end
    end

    describe '#clear' do
        %w(runtime).each do |method|
            it "clears ##{method}" do
                subject.send(method).should receive(:clear)
                subject.clear
            end
        end
    end
end
