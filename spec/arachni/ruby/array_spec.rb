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
                    @arr.includes_tags?( nil ).should == false
                end
            end

            context '[]' do
                it 'returns false' do
                    @arr.includes_tags?( [] ).should == false
                end
            end

            context String do
                context 'when includes the given tag (as either a String or a Symbol)' do
                    it 'returns true' do
                        [ 1 ].includes_tags?( 1 ).should == true
                        [ :tag ].includes_tags?( :tag ).should == true
                        [ :tag ].includes_tags?( 'tag' ).should == true
                        %w(tag).includes_tags?( 'tag' ).should == true
                        %w(tag).includes_tags?( :tag ).should == true
                        [ :tag, 'tag' ].includes_tags?( :tag ).should == true
                        [ :tag, 'tag' ].includes_tags?( 'tag' ).should == true
                    end
                end
                context 'when it does not includes the given tag (as either a String or a Symbol)' do
                    it 'returns false' do
                        [ 1 ].includes_tags?( 2 ).should == false
                        [ :tag ].includes_tags?( :tag1 ).should == false
                        [ :tag ].includes_tags?( 'tag2' ).should == false
                        %w(tag).includes_tags?( 'tag3' ).should == false
                        %w(tag).includes_tags?( :tag5 ).should == false
                        [ :tag, 'tag' ].includes_tags?( :ta5g ).should == false
                        [ :tag, 'tag' ].includes_tags?( 'ta4g' ).should == false
                        [ :t3ag, 'tag1' ].includes_tags?( 'tag' ).should == false
                    end
                end
            end

            context Array do
                context 'when includes any of the given tags (as either a String or a Symbol)' do
                    it 'returns true' do
                        [ 1, 2, 3 ].includes_tags?( [1] ).should == true
                        [ :tag ].includes_tags?( [:tag] ).should == true
                        [ :tag ].includes_tags?( ['tag', 12] ).should == true
                        %w(tag).includes_tags?( ['tag', nil] ).should == true
                        %w(tag).includes_tags?( [:tag] ).should == true
                        [ :tag, 'tag' ].includes_tags?( [:tag] ).should == true
                        [ :tag, 'tag' ].includes_tags?( ['tag', :blah] ).should == true
                    end
                end
                context 'when it does not include any of the given tags (as either a String or a Symbol)' do
                    it 'returns true' do
                        [ 1, 2, 3 ].includes_tags?( [4, 5] ).should == false
                        [ :tag ].includes_tags?( [:ta3g] ).should == false
                        [ :tag ].includes_tags?( ['ta3g', 12] ).should == false
                        %w(tag).includes_tags?( ['ta3g', nil] ).should == false
                        %w(tag).includes_tags?( [:t4ag] ).should == false
                        [ :tag, 'tag' ].includes_tags?( [:t3ag] ).should == false
                        [ :tag, 'tag' ].includes_tags?( ['t2ag', :b3lah] ).should == false
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
            recoded.first.should == "\u2713"
            recoded.last.should == ["\u2713"]
        end
    end

    describe '#chunk' do
        it 'splits the array into chunks' do
            chunks = @arr.chunk( 5 )
            chunks.size.should == 5
            chunks.each { |c| c.size.should == 10 }

            chunks = @arr.chunk( 3 )
            chunks.size.should == 3

            chunks[0].size.should == 17
            chunks[1].size.should == 17
            chunks[2].size.should == 16
        end

        context 'when called without params' do
            it 'splits the array into 2 chunks' do
                chunks = @arr.chunk
                chunks.size.should == 2

                24.times do |i|
                    chunks.first[i].should == i
                    chunks.last[i].should  == i + 25
                end
            end
        end
    end

end
