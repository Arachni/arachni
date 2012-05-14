require_relative '../../spec_helper'

describe String do

    describe '#rdiff' do
        it 'should return the common parts between self and another string' do
            str = <<-END
                This is the first test.
                Not really sure what else to put here...
            END

            str2 = <<-END
                This is the second test.
                Not really sure what else to put here...
                Boo-Yah!
            END

            str.rdiff( str2 ).should == "                This is the  test.\n" +
                "                Not really sure what else to put here"
        end
    end

    describe '#substring?' do
        it 'should return true if the substring exists in self' do
            str = 'my string'
            str.substring?( 'my' ).should be_true
            str.substring?( 'myt' ).should be_false
            str.substring?( 'my ' ).should be_true
        end
    end

end
