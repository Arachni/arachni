# encoding: utf-8
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

    describe '#has_html_tag?' do
        context 'when the string contains the given tag' do
            subject { '<test> stuff' }

            expect_it { to have_html_tag 'test' }
        end

        context 'when the name is preceded by whitespace' do
            subject { '< test> stuff' }

            expect_it { to have_html_tag 'test' }
        end

        context 'when the tag spans multiple lines' do
            subject { "< \n test \n > stuff" }

            expect_it { to have_html_tag 'test' }
        end

        context 'when the tag is mixed case' do
            subject { "< \n tEsT \n > stuff" }

            expect_it { to have_html_tag 'test' }
        end

        context 'when the tag does not close' do
            subject { "< \n test \n stuff" }

            expect_it { to_not have_html_tag 'test' }
        end

        context 'when attributes are given' do
            context 'and the tag attributes match them' do
                subject { '<input type="text">' }

                expect_it { to have_html_tag 'input', /t[e]xt/ }
            end

            context 'and the tag attributes span multiple lines' do
                subject { "<input \n type='text' \n>" }

                expect_it { to have_html_tag 'input', /t[e]xt/ }
            end

            context 'and the tag attributes do notmatch them' do
                subject { '<input type="text">' }

                expect_it { to_not have_html_tag 'input', /blah/ }
            end
        end
    end

    describe '#scan_in_groups' do
        it 'returns regexp matches in named groups' do
            expect(path.scan_in_groups( regex_with_names )).to eq({
                'category'   => 'book',
                'book-id'    => '12',
                'chapter-id' => '3',
                'stuff-id'   => '4'
            })
        end

        context 'when there are no matches' do
            it 'returns an empty hash' do
                expect('test'.scan_in_groups( regex_with_names )).to eq({})
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
            expect(path.sub_in_groups(
                regex_with_names,
                grouped_substitutions
            )).to eq('/new-category/new-book-id/blahahaha/test/chapter-new-chapter-id/stuff-new-stuff-id/12')
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
            expect(path).to eq('/new-category/new-book-id/blahahaha/test/chapter-new-chapter-id/stuff-new-stuff-id/12')
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

            expect(str.rdiff( str2 )).to eq("                This is the  test.\n" +
                '                Not really sure what else to put here')
        end
    end

    describe '#diff_ratio' do
        context 'when the strings are identical' do
            it 'returns 0.0' do
                expect(''.diff_ratio( '' )).to eq(0)
                expect('test'.diff_ratio( 'test' )).to eq(0)
                expect('test this'.diff_ratio( 'test this' )).to eq(0)
            end
        end
        context 'when the strings completely different' do
            it 'returns 1.0' do
                expect(''.diff_ratio( 'toast' )).to eq(1)
                expect('test'.diff_ratio( 'toast' )).to eq(1)
                expect('test this'.diff_ratio( 'toast that' )).to eq(1)
            end
        end
        context 'when the strings share less than half of their words' do
            it 'returns < 0.5' do
                expect('test this here now'.diff_ratio( 'test that here now' )).to be > 0.0
                expect('test this here now'.diff_ratio( 'test that here now' )).to be < 0.5
            end
        end
        context 'when the strings share more than half of their words' do
            it 'returns > 0.5' do
                expect('test this here now'.diff_ratio( 'test that here later' )).to be > 0.0
                expect('test this here now'.diff_ratio( 'test that here later' )).to be > 0.5
            end
        end
    end

    describe '#escape_double_quote' do
        it 'escapes double quotes' do
            expect('stuff" here'.escape_double_quote).to eq 'stuff\" here'
        end
    end

    describe '#words' do
        context 'when strict is set to true' do
            it 'does not include boundaries' do
                expect('blah.bloo<ha hoo'.words( true ).sort).to eq(%w(blah bloo ha hoo).sort)
            end
        end
        context 'when strict is set to false' do
            it 'includes boundaries' do
                expect('blah.bloo<ha hoo'.words( false ).sort).to eq([" ", ".", "<", "blah", "bloo", "ha", "hoo"] .sort)
            end
        end
        context 'when strict is not specified' do
            it 'defaults to false' do
                expect('blah.bloo<ha hoo'.words.sort).to eq('blah.bloo<ha hoo'.words( false ).sort)
            end
        end
    end

    describe '#recode!' do
        subject { "abc\u3042\x81" }

        it 'removes invalid characters' do
            subject.recode!
            expect(subject).to eq("abcあ�")
        end
    end

    describe '#recode' do
        subject { "abc\u3042\x81" }

        it 'returns a copy of the String without invalid characters' do
            expect(subject.recode).to eq("abcあ�")
        end
    end

    describe '#persistent_hash' do
        it 'returns an Integer' do
            expect('test'.persistent_hash).to be_kind_of Integer
        end

        context 'when two strings are equal' do
            it 'returns equal values' do
                expect('test'.persistent_hash).to eq('test'.persistent_hash)
            end
        end
        context 'when two strings are not equal' do
            it 'returns different values' do
                expect('test'.persistent_hash).not_to eq('testa'.persistent_hash)
            end
        end
    end

    describe '#binary?' do
        context 'when the content is' do
            context 'binary' do
                it 'returns true' do
                    expect("\ff\ff\ff".binary?).to be_truthy
                end
            end
            context 'text' do
                it 'returns false' do
                    expect('test'.binary?).to be_falsey
                end
            end
        end
    end

    describe '#longest_word' do
        it 'returns the longest word' do
            expect('o tw longest'.longest_word).to eq('longest')
        end
    end

    describe '#shortest_word' do
        it 'returns the longest word' do
            expect('o tw longest'.shortest_word).to eq('o')
        end
    end
end
