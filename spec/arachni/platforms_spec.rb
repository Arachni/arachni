require 'spec_helper'

describe Arachni::Platforms do

    let(:platforms) { described_class.new }

    it 'is Enumerable' do
        platforms.is_a? Enumerable
    end

    describe '#initialize' do
        describe 'platforms' do
            it 'initializes the instance with the gievn platforms' do
                described_class.new( %w(php unix) ).to_a.should ==
                    [:php, :unix]
            end

            context 'when invalid platforms are given' do
                it 'raises Arachni::Platforms::Error::Invalid' do
                    expect {
                        described_class.new( %w(stuff unix) )
                    }.to raise_error Arachni::Platforms::Error::Invalid
                end
            end
        end
    end

    describe '#pick_applicable' do
        it 'returns only data relevant to the applicable platforms' do
            applicable_data = {
                unix:    [ '*NIX stuff' ],
                linux:   [ 'Linux stuff' ],
            }
            data = applicable_data.merge( windows:[ 'Windows stuff' ] )

            platforms << :unix << :linux
            platforms.pick_applicable( data ).should == applicable_data
        end

        context 'when invalid platforms are given' do
            it 'raises Arachni::Platforms::Error::Invalid' do
                expect {
                    platforms.pick_applicable(  { blah: 1, unix: 'stuff' } )
                }.to raise_error Arachni::Platforms::Error::Invalid
            end
        end
    end

    describe '#valid?' do
        context 'when given' do
            context 'Array' do
                context 'with valid platforms' do
                    it 'returns true' do
                        platforms.valid?( [:unix, :linux] ).should be_true
                    end
                end
                context 'with invalid platforms' do
                    it 'returns false' do
                        platforms.valid?( [:unix, :blah] ).should be_false
                    end
                end
            end

            context 'String' do
                context 'with valid platform' do
                    it 'returns true' do
                        platforms.valid?( :unix ).should be_true
                    end
                end
                context 'with invalid platform' do
                    it 'returns false' do
                        platforms.valid?( :blah ).should be_false
                    end
                end
            end
        end
    end

    describe '#invalid?' do
        context 'when given' do
            context 'Array' do
                context 'with valid platforms' do
                    it 'returns false' do
                        platforms.invalid?( [:blah, :linux] ).should be_true
                    end
                end
                context 'with invalid platforms' do
                    it 'returns false' do
                        platforms.invalid?( [:unix, :php] ).should be_false
                    end
                end
            end

            context 'String' do
                context 'with valid platform' do
                    it 'returns true' do
                        platforms.invalid?( :blah ).should be_true
                    end
                end
                context 'with invalid platform' do
                    it 'returns false' do
                        platforms.invalid?( :jsp ).should be_false
                    end
                end
            end
        end
    end

    describe '#<<' do
        it 'adds a new platform' do
            platforms << :unix
            platforms.to_a.should == [:unix]
        end

        it 'returns self' do
            (platforms << :unix).should == platforms
        end

        context 'when an invalid platform is given' do
            it 'raises Arachni::Platforms::Error::Invalid' do
                expect {
                    platforms << :blah
                }.to raise_error Arachni::Platforms::Error::Invalid
            end
        end
    end

    describe '#merge' do
        context 'with valid platforms' do
            it 'returns a copy of self including the given platforms' do
                platforms << :unix
                platforms.merge( [:php, :unix] ).to_a.sort == [:unix, :php].sort
                platforms.to_a.should == [:unix]
            end
        end
        context 'with invalid platforms' do
            it 'raises Arachni::Platforms::Error::Invalid' do
                expect {
                    platforms.merge( [:blah] )
                }.to raise_error Arachni::Platforms::Error::Invalid
            end
        end
    end

    describe '#merge!' do
        context 'with valid platforms' do
            it 'updates self with the given platforms' do
                platforms << :unix
                platforms.merge!( [:php, :unix] )
                platforms.to_a.sort.should == [:php, :unix].sort
            end
        end
        context 'with invalid platforms' do
            it 'raises Arachni::Platforms::Error::Invalid' do
                expect {
                    platforms.merge!( [:blah] )
                }.to raise_error Arachni::Platforms::Error::Invalid
            end
        end
    end

    describe '#|' do
        context 'with valid platforms' do
            it 'returns a union' do
                platforms << :unix

                union = (platforms | [:php, :mysql] )
                union.sort == [:unix, :php, :mysql].sort
                union.is_a? described_class

                platforms.to_a.should == [:unix].sort
            end
        end
        context 'with invalid platforms' do
            it 'raises Arachni::Platforms::Error::Invalid' do
                expect {
                    platforms | [:blah]
                }.to raise_error Arachni::Platforms::Error::Invalid
            end
        end
    end

    describe '#include?' do
        context 'when it includes the given platform' do
            it 'returns true' do
                platforms << :unix
                platforms.include?( :unix ).should be_true
            end
        end
        context 'when it does not include the given platform' do
            it 'returns false' do
                platforms << :asp
                platforms.include?( :unix ).should be_false
            end
        end
        context 'when given an invalid platform' do
            it 'raises Arachni::Platforms::Error::Invalid' do
                expect {
                    platforms.include? :blah
                }.to raise_error Arachni::Platforms::Error::Invalid
            end
        end
    end

    describe '#include_any?' do
        context 'when it includes any of the given platforms' do
            it 'returns true' do
                platforms << :unix
                platforms.include_any?( [ :unix, :jsp ] ).should be_true
            end
        end
        context 'when it does not include any of the given platforms' do
            it 'returns false' do
                platforms << :asp
                platforms.include_any?( [ :unix, :jsp ] ).should be_false
            end
        end
        context 'when given an invalid platform' do
            it 'raises Arachni::Platforms::Error::Invalid' do
                expect {
                    platforms.include_any?( [ :unix, :blah ] )
                }.to raise_error Arachni::Platforms::Error::Invalid
            end
        end
    end

    describe '#each' do
        it 'iterates over all applicable platforms' do
            platforms = [ :unix, :php, :pgsql].sort

            iterated = []
            described_class.new( platforms ).each do |platform|
                iterated << platform
            end

            iterated.sort.should == platforms
        end
    end

    describe '#empty?' do
        context 'when there are no platforms' do
            it 'returns true' do
                platforms.empty?.should be_true
            end
        end
        context 'when there are platforms' do
            it 'returns false' do
                platforms << :asp
                platforms.empty?.should be_false
            end
        end
    end

    describe '#any?' do
        context 'when there are no platforms' do
            it 'returns false' do
                platforms.any?.should be_false
            end
        end
        context 'when there are platforms' do
            it 'returns true' do
                platforms << :asp
                platforms.any?.should be_true
            end
        end
    end

    describe '#dup' do
        it 'creates a copy' do
            platforms << :unix
            cplatforms = platforms.dup
            cplatforms << :jsp

            cplatforms.sort.should == [:unix, :jsp].sort
            platforms.to_a.should == [:unix]
        end
    end
end
