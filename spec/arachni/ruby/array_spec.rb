require 'spec_helper'

describe Array do
    before( :all ) do
        @arr = Array.new
        50.times { |i| @arr << i }
    end

    describe '#includes_tag?' do
        context 'when passed' do
            context 'nil' do
                it 'returns false' do
                    expect(@arr.includes_tags?( nil )).to eq(false)
                end
            end

            context '[]' do
                it 'returns false' do
                    expect(@arr.includes_tags?( [] )).to eq(false)
                end
            end

            context 'String' do
                context 'when includes the given tag (as either a String or a Symbol)' do
                    it 'returns true' do
                        expect([ 1 ].includes_tags?( 1 )).to eq(true)
                        expect([ :tag ].includes_tags?( :tag )).to eq(true)
                        expect([ :tag ].includes_tags?( 'tag' )).to eq(true)
                        expect(%w(tag).includes_tags?( 'tag' )).to eq(true)
                        expect(%w(tag).includes_tags?( :tag )).to eq(true)
                        expect([ :tag, 'tag' ].includes_tags?( :tag )).to eq(true)
                        expect([ :tag, 'tag' ].includes_tags?( 'tag' )).to eq(true)
                    end
                end
                context 'when it does not includes the given tag (as either a String or a Symbol)' do
                    it 'returns false' do
                        expect([ 1 ].includes_tags?( 2 )).to eq(false)
                        expect([ :tag ].includes_tags?( :tag1 )).to eq(false)
                        expect([ :tag ].includes_tags?( 'tag2' )).to eq(false)
                        expect(%w(tag).includes_tags?( 'tag3' )).to eq(false)
                        expect(%w(tag).includes_tags?( :tag5 )).to eq(false)
                        expect([ :tag, 'tag' ].includes_tags?( :ta5g )).to eq(false)
                        expect([ :tag, 'tag' ].includes_tags?( 'ta4g' )).to eq(false)
                        expect([ :t3ag, 'tag1' ].includes_tags?( 'tag' )).to eq(false)
                    end
                end
            end

            context 'Array' do
                context 'when includes any of the given tags (as either a String or a Symbol)' do
                    it 'returns true' do
                        expect([ 1, 2, 3 ].includes_tags?( [1] )).to eq(true)
                        expect([ :tag ].includes_tags?( [:tag] )).to eq(true)
                        expect([ :tag ].includes_tags?( ['tag', 12] )).to eq(true)
                        expect(%w(tag).includes_tags?( ['tag', nil] )).to eq(true)
                        expect(%w(tag).includes_tags?( [:tag] )).to eq(true)
                        expect([ :tag, 'tag' ].includes_tags?( [:tag] )).to eq(true)
                        expect([ :tag, 'tag' ].includes_tags?( ['tag', :blah] )).to eq(true)
                    end
                end
                context 'when it does not include any of the given tags (as either a String or a Symbol)' do
                    it 'returns true' do
                        expect([ 1, 2, 3 ].includes_tags?( [4, 5] )).to eq(false)
                        expect([ :tag ].includes_tags?( [:ta3g] )).to eq(false)
                        expect([ :tag ].includes_tags?( ['ta3g', 12] )).to eq(false)
                        expect(%w(tag).includes_tags?( ['ta3g', nil] )).to eq(false)
                        expect(%w(tag).includes_tags?( [:t4ag] )).to eq(false)
                        expect([ :tag, 'tag' ].includes_tags?( [:t3ag] )).to eq(false)
                        expect([ :tag, 'tag' ].includes_tags?( ['t2ag', :b3lah] )).to eq(false)
                    end
                end
            end
        end
    end

    describe '#recode' do
        it 'recursively converts String data to UTF8' do
            recoded = [
                "\xE2\x9C\x93",
                [ "\xE2\x9C\x93" ]
            ].recode
            expect(recoded.first).to eq("\u2713")
            expect(recoded.last).to eq(["\u2713"])
        end
    end

    describe '#chunk' do
        it 'splits the array into chunks' do
            chunks = @arr.chunk( 5 )
            expect(chunks.size).to eq(5)
            chunks.each { |c| expect(c.size).to eq(10) }

            chunks = @arr.chunk( 3 )
            expect(chunks.size).to eq(3)

            expect(chunks[0].size).to eq(17)
            expect(chunks[1].size).to eq(17)
            expect(chunks[2].size).to eq(16)
        end

        context 'when called without params' do
            it 'splits the array into 2 chunks' do
                chunks = @arr.chunk
                expect(chunks.size).to eq(2)

                24.times do |i|
                    expect(chunks.first[i]).to eq(i)
                    expect(chunks.last[i]).to  eq(i + 25)
                end
            end
        end
    end

end
