require 'spec_helper'

describe Arachni::Platform::List do

    let(:platforms) { described_class.new [:unix, :linux, :freebsd, :php, :windows, :asp] }

    describe '#initialize' do
        describe 'platforms' do
            it 'initializes the instance with the valid platforms' do
                described_class.new( %w(php unix) ).valid.sort.should == [:php, :unix].sort
            end

            context 'when invalid platforms are given' do
                it 'raises Arachni::Platform::Error::Invalid' do
                    expect {
                        platforms << :stuff
                    }.to raise_error Arachni::Platform::Error::Invalid
                end
            end
        end
    end

    describe '#valid' do
        it 'returns valid platforms' do
            described_class.new( %w(php unix) ).valid.sort.should == [:php, :unix].sort
        end
    end

    describe '#pick' do
        it 'returns only data relevant to the applicable platforms' do
            applicable_data = {
                unix: [ 'UNIX stuff' ],
                php:  [ 'PHP stuff' ]
            }
            data = applicable_data.merge( windows: [ 'Windows stuff' ] )

            platforms << :unix << :php
            platforms.pick( data ).should == applicable_data
        end

        context 'when a child has been specified' do
            context 'and data for the parent are given' do
                context 'and no data for children are given' do
                    it 'includes data for the parent' do
                        platforms = described_class.new(
                            parent: {
                                child: {},
                                child2: {},
                                child3: {},
                            },
                            stuff:      {},
                            irrelevant: {}
                        )

                        applicable_data = {
                            parent: [ 'Parent stuff' ],
                            stuff:  [ 'Just stuff' ]
                        }
                        data = applicable_data.merge( irrelevant: [ 'Irrelevant stuff' ] )

                        platforms << :child << :stuff

                        platforms.pick( data ).should == applicable_data
                    end
                end
            end
        end

        context 'when a parent has been specified' do
            it 'includes all children' do
                platforms = described_class.new(
                    parent: {
                        child: {},
                        child2: {},
                        child3: {},
                    },
                    stuff:      {},
                    irrelevant: {}
                )

                applicable_data = {
                    child:  [ 'Child stuff' ],
                    child2: [ 'Child2 stuff' ],
                    stuff:  [ 'Just stuff' ]
                }
                data = applicable_data.merge( irrelevant: [ 'Irrelevant stuff' ] )

                platforms << :parent << :stuff

                platforms.pick( data ).should == applicable_data
            end

            context 'and specific OS flavors are specified' do
                it 'removes parent types' do
                    platforms = described_class.new(
                        parent: {
                            child: {},
                            child2: {},
                            child3: {},
                        },
                        another_parent: {
                            another_child: {},
                            another_child2: {},
                            another_child3: {},
                        },
                        stuff:           {},
                        more_stuff:      {},
                        even_more_stuff: {},
                        irrelevant:      {}
                    )

                    applicable_data = {
                        # This should not be in the picked data.
                        parent:         [ 'Parent stuff' ],

                        # This should not be in the picked data.
                        another_parent:  [ 'Another parent stuff' ],

                        child:           [ 'Child stuff' ],
                        another_child:   [ 'Another child stuff' ],
                        even_more_stuff: [ 'Even more stuff' ]
                    }
                    data = applicable_data.merge( irrelevant: [ 'Ignore this stuff' ] )

                    platforms << :parent << :child << :stuff << :another_parent << :another_child << :even_more_stuff

                    applicable_data.delete( :parent )
                    applicable_data.delete( :another_parent )

                    platforms.pick( data ).should == applicable_data
                end
            end
        end

        context 'when invalid platforms are given' do
            it 'raises Arachni::Platform::Error::Invalid' do
                expect {
                    platforms.pick(  { blah: 1, unix: 'stuff' } )
                }.to raise_error Arachni::Platform::Error::Invalid
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
                        platforms.invalid?( :unix ).should be_false
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
            it 'raises Arachni::Platform::Error::Invalid' do
                expect {
                    platforms << :blah
                }.to raise_error Arachni::Platform::Error::Invalid
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
            it 'raises Arachni::Platform::Error::Invalid' do
                expect {
                    platforms.merge( [:blah] )
                }.to raise_error Arachni::Platform::Error::Invalid
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
            it 'raises Arachni::Platform::Error::Invalid' do
                expect {
                    platforms.merge!( [:blah] )
                }.to raise_error Arachni::Platform::Error::Invalid
            end
        end
    end

    describe '#update' do
        context 'with valid platforms' do
            it 'updates self with the given platforms' do
                platforms << :unix
                platforms.update( [:php, :unix] )
                platforms.to_a.sort.should == [:php, :unix].sort
            end
        end
        context 'with invalid platforms' do
            it 'raises Arachni::Platform::Error::Invalid' do
                expect {
                    platforms.update( [:blah] )
                }.to raise_error Arachni::Platform::Error::Invalid
            end
        end
    end

    describe '#|' do
        context 'with valid platforms' do
            it 'returns a union' do
                platforms << :unix

                union = (platforms | [:php, :freebsd] )
                union.sort == [:unix, :php, :freebsd].sort
                union.is_a? described_class

                platforms.to_a.should == [:unix].sort
            end
        end
        context 'with invalid platforms' do
            it 'raises Arachni::Platform::Error::Invalid' do
                expect {
                    platforms | [:blah]
                }.to raise_error Arachni::Platform::Error::Invalid
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
            it 'raises Arachni::Platform::Error::Invalid' do
                expect {
                    platforms.include? :blah
                }.to raise_error Arachni::Platform::Error::Invalid
            end
        end
    end

    describe '#include_any?' do
        context 'when it includes any of the given platforms' do
            it 'returns true' do
                platforms << :unix
                platforms.include_any?( [ :unix, :php ] ).should be_true
            end
        end
        context 'when it does not include any of the given platforms' do
            it 'returns false' do
                platforms << :asp
                platforms.include_any?( [ :unix, :php ] ).should be_false
            end
        end
        context 'when given an invalid platform' do
            it 'raises Arachni::Platform::Error::Invalid' do
                expect {
                    platforms.include_any?( [ :unix, :blah ] )
                }.to raise_error Arachni::Platform::Error::Invalid
            end
        end
    end

    describe '#each' do
        it 'iterates over all applicable platforms' do
            included_platforms = platforms.sort

            iterated = []
            platforms.each do |platform|
                iterated << platform
            end

            iterated.sort.should == included_platforms
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

    describe '#clear' do
        it 'clears the global platform DB' do
            platforms << :unix
            platforms.empty?.should be_false
            platforms.clear
            platforms.empty?.should be_true
        end
    end

    describe '#dup' do
        it 'creates a copy' do
            platforms << :unix
            cplatforms = platforms.dup
            cplatforms << :php

            cplatforms.sort.should == [:unix, :php].sort
            platforms.to_a.should == [:unix]
        end
    end
end
