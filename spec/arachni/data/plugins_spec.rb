require 'spec_helper'

describe Arachni::Data::Plugins do
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

    describe '#statistics' do
        it 'includes plugin names' do
            plugins.load :distributable
            result = { 'stuff' => 1 }

            subject.store( plugins.create(:distributable), result )

            subject.statistics[:names].should == [:distributable]
        end
    end

    describe '#results' do
        it 'returns a Hash' do
            subject.results.should be_kind_of Hash
        end
    end

    describe '#store' do
        it 'stores plugin results' do
            plugins.load :distributable
            result = { stuff: 1 }

            subject.store( plugins.create(:distributable), result )
            subject.results[:distributable][:results].should == result
        end
    end

    describe '#merge_results' do
        it 'merges the results of the distributable plugins' do
            plugins.load :distributable

            results = [ distributable: { results: { 'stuff' => 2 } } ]
            subject.store( plugins.create(:distributable), 'stuff' => 1 )

            subject.merge_results( plugins, results )
            subject.results[:distributable][:results]['stuff'].should == 3
        end
    end

    describe '#dump' do
        it 'stores #results to disk' do
            subject.store( plugins.create(:distributable), stuff: 1 )
            subject.dump( dump_directory )

            results_file = "#{dump_directory}/results/distributable"
            File.exists?( results_file ).should be_true
            subject.results.should == {
                distributable: Marshal.load( IO.read( results_file ) )
            }
        end
    end

    describe '.load' do
        it 'loads #results from disk' do
            subject.store( plugins.create(:distributable), stuff: 1 )
            subject.dump( dump_directory )

            subject.results.should == described_class.load( dump_directory ).results
        end
    end

    describe '#clear' do
        %w(results).each do |method|
            it "clears ##{method}" do
                subject.send(method).should receive(:clear)
                subject.clear
            end
        end
    end
end
