require 'spec_helper'
require 'tempfile'

describe IO do
    describe '#tail' do
        it 'returns the specified amount of lines from the bottom of an IO stream' do
            Tempfile.open( 'w' ) do |f|
                f.write <<-EOSTR
                    Test
                    Test2
                    Test3
                    Test4
                    Test5
                EOSTR
                f.flush

                expect(f.tail( 4 )).to eq([
                    '                    Test2',
                    '                    Test3',
                    '                    Test4',
                    '                    Test5'
                ])
            end
        end
    end
end
