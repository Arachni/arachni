require 'spec_helper'

describe Arachni::State::Plugins do
    subject { described_class.new }
    let(:plugins) { @framework.plugins }
    before(:each) do
        @framework = Arachni::Framework.new
        subject.clear
    end
    after(:each) { @framework.reset }

    describe '#results' do
        it 'returns a Hash' do
            subject.results.should be_kind_of Hash
        end
    end

    describe '#runtime' do
        it 'returns a Hash' do
            subject.runtime.should be_kind_of Hash
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

            results = [ distributable: { results: { stuff: 2 } } ]
            subject.store( plugins.create(:distributable), stuff: 1 )

            subject.merge_results( plugins, results )[:distributable][:results][:stuff].should == 3
        end
    end

    describe '#clear' do
        %w(results runtime).each do |method|
            it "clears ##{method}" do
                subject.send(method).should receive(:clear)
                subject.clear
            end
        end
    end
end
