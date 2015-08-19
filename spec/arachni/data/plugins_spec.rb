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

            expect(subject.statistics[:names]).to eq([:distributable])
        end
    end

    describe '#results' do
        it 'returns a Hash' do
            expect(subject.results).to be_kind_of Hash
        end
    end

    describe '#store' do
        it 'stores plugin results' do
            plugins.load :distributable
            result = { stuff: 1 }

            subject.store( plugins.create(:distributable), result )
            expect(subject.results[:distributable][:results]).to eq(result)
        end
    end

    describe '#merge_results' do
        it 'merges the results of the distributable plugins' do
            plugins.load :distributable

            results = [ distributable: { results: { 'stuff' => 2 } } ]
            subject.store( plugins.create(:distributable), 'stuff' => 1 )

            subject.merge_results( plugins, results )
            expect(subject.results[:distributable][:results]['stuff']).to eq(3)
        end

        context 'when a merge error occurs' do
            it 'defaults to only using the local results' do
                plugins.load :distributable

                results = [ distributable: { results: { 'stuff' => 2 } } ]
                subject.store( plugins.create(:distributable), 'stuff' => 1 )

                allow(plugins[:distributable]).to receive(:merge) { raise }

                subject.merge_results( plugins, results )
                expect(subject.results[:distributable][:results]['stuff']).to eq(1)
            end
        end
    end

    describe '#dump' do
        it 'stores #results to disk' do
            subject.store( plugins.create(:distributable), stuff: 1 )
            subject.dump( dump_directory )

            results_file = "#{dump_directory}/results/distributable"
            expect(File.exists?( results_file )).to be_truthy
            expect(subject.results).to eq({
                distributable: Marshal.load( IO.read( results_file ) )
            })
        end
    end

    describe '.load' do
        it 'loads #results from disk' do
            subject.store( plugins.create(:distributable), stuff: 1 )
            subject.dump( dump_directory )

            expect(subject.results).to eq(described_class.load( dump_directory ).results)
        end
    end

    describe '#clear' do
        %w(results).each do |method|
            it "clears ##{method}" do
                expect(subject.send(method)).to receive(:clear)
                subject.clear
            end
        end
    end
end
