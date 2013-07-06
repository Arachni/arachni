require 'spec_helper'

describe Arachni::Module::KeyFiller do

    describe '#fill' do
        it 'fills in all inputs with appropriate seed values' do
            described_class.fill(
                'nAMe'    => nil,
                'usEr'    => nil,
                'uSR'     => nil,
                'pAsS'    => nil,
                'tXt'     => nil,
                'nUm'     => nil,
                'AmoUnt'  => nil,
                'mAIL'    => nil,
                'aCcouNt' => nil,
                'iD'      => nil
            ).should == {
                'nAMe'    => 'arachni_name',
                'usEr'    => 'arachni_user',
                'uSR'     => 'arachni_user',
                'pAsS'    => '5543!%arachni_secret',
                'tXt'     => 'arachni_text',
                'nUm'     => '132',
                'AmoUnt'  => '100',
                'mAIL'    => 'arachni@email.gr',
                'aCcouNt' => '12',
                'iD'      => '1'
            }
        end

        context 'when there is a default value' do
            it 'skips it' do
                with_values = {
                    'stuff' => 'blah'
                }
                described_class.fill( with_values ) == with_values
            end
        end
    end

end
