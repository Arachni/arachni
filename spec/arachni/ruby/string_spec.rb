require 'spec_helper'

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

    describe '#diff_ratio' do
        context 'when the strings are identical' do
            it 'returns 0.0' do
                'test'.diff_ratio( 'test' ).should == 0
                'test this'.diff_ratio( 'test this' ).should == 0
            end
        end
        context 'when the strings completely different' do
            it 'returns 1.0' do
                'test'.diff_ratio( 'toast' ).should == 1
                'test this'.diff_ratio( 'toast that' ).should == 1
            end
        end
        context 'when the strings share less than half of their words' do
            it 'returns < 0.5' do
                'test this here now'.diff_ratio( 'test that here now' ).should > 0.0
                'test this here now'.diff_ratio( 'test that here now' ).should < 0.5
            end
        end
        context 'when the strings share more than half of their words' do
            it 'returns > 0.5' do
                'test this here now'.diff_ratio( 'test that here later' ).should > 0.0
                'test this here now'.diff_ratio( 'test that here later' ).should > 0.5
            end
        end
    end

    describe '#words' do
        context 'when strict is set to true' do
            it 'does not include boundaries' do
                'blah.bloo<ha hoo'.words( true ).sort.should == %w(blah bloo ha hoo).sort
            end
        end
        context 'when strict is set to false' do
            it 'includes boundaries' do
                'blah.bloo<ha hoo'.words( false ).sort.should ==  [" ", ".", "<", "blah", "bloo", "ha", "hoo"] .sort
            end
        end
        context 'when strict is not specified' do
            it 'defaults to false' do
                'blah.bloo<ha hoo'.words.sort.should == 'blah.bloo<ha hoo'.words( false ).sort
            end
        end
    end

    describe '#substring?' do
        it 'returns true if the substring exists in self' do
            str = 'my string'
            str.substring?( 'my' ).should be_true
            str.substring?( 'myt' ).should be_false
            str.substring?( 'my ' ).should be_true
        end
    end

    describe '#persistent_hash' do
        it 'returns an Integer' do
            'test'.persistent_hash.should be_kind_of Integer
        end

        context 'when two strings are equal' do
            it 'returns equal values' do
                'test'.persistent_hash.should == 'test'.persistent_hash
            end
        end
        context 'when two strings are not equal' do
            it 'returns different values' do
                'test'.persistent_hash.should_not == 'testa'.persistent_hash
            end
        end
    end

    describe '#binary?' do
        context 'when the content is' do
            context 'binary' do
                it 'returns true' do
                    "\ff\ff\ff".binary?.should be_true
                end
            end
            context 'text' do
                it 'returns false' do
                    'test'.binary?.should be_false
                end
            end
        end
    end

end
