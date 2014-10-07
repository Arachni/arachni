require 'spec_helper'

describe Arachni::OptionGroups::Snapshot do
    include_examples 'option_group'
    subject { described_class.new }

    %w(save_path).each do |method|
        it { should respond_to method }
        it { should respond_to "#{method}=" }
    end

    describe '.save_path' do
        context "when #{Arachni::OptionGroups::Paths}.config['framework']['snapshots']" do
            it 'returns it' do
                Arachni::OptionGroups::Paths.stub(:config) do
                    {
                        'framework' => {
                            'snapshots' => 'stuff/'
                        }
                    }
                end

                subject.save_path.should == 'stuff/'
            end
        end
    end

end
