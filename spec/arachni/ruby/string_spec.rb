require 'spec_helper'

describe String do

    let(:path) { '/book/12/blahahaha/test/chapter-3/stuff4/12' }
    let(:regex_with_names) do
        /
            \/(?<category>\w+)         # matches category type
            \/                         # path separator
            (?<book-id>\d+)            # matches book ID numbers
            \/                         # path separator
            .*                         # irrelevant
            \/                         # path separator
            chapter-(?<chapter-id>\d+) # matches chapter ID numbers
            \/                         # path separator
            stuff(?<stuff-id>\d+)      # matches stuff ID numbers
        /x
    end
    let(:grouped_substitutions) do
        {
            'category'   => 'new-category',
            'book-id'    => 'new-book-id',
            'chapter-id' => 'new-chapter-id',
            'stuff-id'   => '-new-stuff-id'
        }
    end

    describe '#scan_in_groups' do
        it 'returns regexp matches in named groups' do
            path.scan_in_groups( regex_with_names ).should == {
                'category'   => 'book',
                'book-id'    => '12',
                'chapter-id' => '3',
                'stuff-id'   => '4'
            }
        end

        context 'when there are no matches' do
            it 'returns an empty hash' do
                'test'.scan_in_groups( regex_with_names ).should == {}
            end
        end

        context 'when the regexp does not contain named captures' do
            it 'raises ArgumentError' do
                expect { 'test'.scan_in_groups( /./ ) }.to raise_error ArgumentError
            end
        end
    end

    describe '#sub_in_groups' do
        it 'substitutes the named matches' do
            path.sub_in_groups(
                regex_with_names,
                grouped_substitutions
            ).should == '/new-category/new-book-id/blahahaha/test/chapter-new-chapter-id/stuff-new-stuff-id/12'
        end

        context 'when using invalid group names' do
            it 'raises IndexError' do
                grouped_substitutions['blah'] = 'blah2'

                expect do
                    path.sub_in_groups!( regex_with_names, grouped_substitutions )
                end.to raise_error IndexError
            end
        end
    end

    describe '#sub_in_groups!' do
        it 'substitutes the named matches in place' do
            path.sub_in_groups!( regex_with_names, grouped_substitutions )
            path.should == '/new-category/new-book-id/blahahaha/test/chapter-new-chapter-id/stuff-new-stuff-id/12'
        end

        context 'when using invalid group names' do
            it 'raises IndexError' do
                grouped_substitutions['blah'] = 'blah2'

                expect do
                    path.sub_in_groups!( regex_with_names, grouped_substitutions )
                end.to raise_error IndexError
            end
        end

    end

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
                '                Not really sure what else to put here'
        end
    end

    describe '#diff_ratio' do
        context 'when the strings are identical' do
            it 'returns 0.0' do
                ''.diff_ratio( '' ).should == 0
                'test'.diff_ratio( 'test' ).should == 0
                'test this'.diff_ratio( 'test this' ).should == 0
            end
        end
        context 'when the strings completely different' do
            it 'returns 1.0' do
                ''.diff_ratio( 'toast' ).should == 1
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

    describe '#recode!' do
        subject { "abc\u3042\x81" }

        it 'removes invalid characters' do
            subject.recode!
            subject.should == "abcあ�"
        end
    end

    describe '#recode' do
        subject { "abc\u3042\x81" }

        it 'returns a copy of the String without invalid characters' do
            subject.recode.should == "abcあ�"
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

    describe '#longest_word' do
        it 'returns the longest word' do
            'o tw longest'.longest_word.should == 'longest'
        end
    end

    describe '#shortest_word' do
        it 'returns the longest word' do
            'o tw longest'.shortest_word.should == 'o'
        end
    end
end
