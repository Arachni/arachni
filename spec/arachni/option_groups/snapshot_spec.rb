require 'spec_helper'

describe Arachni::OptionGroups::Snapshot do
    include_examples 'option_group'
    subject { described_class.new }

    %w(save_path).each do |method|
        it { is_expected.to respond_to method }
        it { is_expected.to respond_to "#{method}=" }
    end

    describe '.save_path' do
        context "when #{Arachni::OptionGroups::Paths}.config['framework']['snapshots']" do
            it 'returns it' do
                allow(Arachni::OptionGroups::Paths).to receive(:config) do
                    {
                        'framework' => {
                            'snapshots' => 'stuff/'
                        }
                    }
                end

                expect(subject.save_path).to eq('stuff/')
            end
        end
    end

end
