require 'spec_helper'

describe Arachni::Platform::List do

    let(:platforms) { described_class.new [:unix, :linux, :freebsd, :php, :windows, :asp] }

    describe '#initialize' do
        describe 'platforms' do
            it 'initializes the instance with the valid platforms' do
                expect(described_class.new( %w(php unix) ).valid.sort).to eq([:php, :unix].sort)
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
            expect(described_class.new( %w(php unix) ).valid.sort).to eq([:php, :unix].sort)
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
            expect(platforms.pick( data )).to eq(applicable_data)
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

                        expect(platforms.pick( data )).to eq(applicable_data)
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

                expect(platforms.pick( data )).to eq(applicable_data)
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

                    expect(platforms.pick( data )).to eq(applicable_data)
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
                        expect(platforms.valid?( [:unix, :linux] )).to be_truthy
                    end
                end
                context 'with invalid platforms' do
                    it 'returns false' do
                        expect(platforms.valid?( [:unix, :blah] )).to be_falsey
                    end
                end
            end

            context 'String' do
                context 'with valid platform' do
                    it 'returns true' do
                        expect(platforms.valid?( :unix )).to be_truthy
                    end
                end
                context 'with invalid platform' do
                    it 'returns false' do
                        expect(platforms.valid?( :blah )).to be_falsey
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
                        expect(platforms.invalid?( [:blah, :linux] )).to be_truthy
                    end
                end
                context 'with invalid platforms' do
                    it 'returns false' do
                        expect(platforms.invalid?( [:unix, :php] )).to be_falsey
                    end
                end
            end

            context 'String' do
                context 'with valid platform' do
                    it 'returns true' do
                        expect(platforms.invalid?( :blah )).to be_truthy
                    end
                end
                context 'with invalid platform' do
                    it 'returns false' do
                        expect(platforms.invalid?( :unix )).to be_falsey
                    end
                end
            end
        end
    end

    describe '#<<' do
        it 'adds a new platform' do
            platforms << :unix
            expect(platforms.to_a).to eq([:unix])
        end

        it 'returns self' do
            expect(platforms << :unix).to eq(platforms)
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
                expect(platforms.merge( [:php, :unix] ).to_a.sort).to eq([:unix, :php].sort)
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
                expect(platforms.to_a.sort).to eq([:php, :unix].sort)
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
                expect(platforms.to_a.sort).to eq([:php, :unix].sort)
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

                expect(platforms.to_a).to eq([:unix].sort)
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
                expect(platforms.include?( :unix )).to be_truthy
            end
        end
        context 'when it does not include the given platform' do
            it 'returns false' do
                platforms << :asp
                expect(platforms.include?( :unix )).to be_falsey
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
                expect(platforms.include_any?( [ :unix, :php ] )).to be_truthy
            end
        end
        context 'when it does not include any of the given platforms' do
            it 'returns false' do
                platforms << :asp
                expect(platforms.include_any?( [ :unix, :php ] )).to be_falsey
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

            expect(iterated.sort).to eq(included_platforms)
        end
    end

    describe '#empty?' do
        context 'when there are no platforms' do
            it 'returns true' do
                expect(platforms.empty?).to be_truthy
            end
        end
        context 'when there are platforms' do
            it 'returns false' do
                platforms << :asp
                expect(platforms.empty?).to be_falsey
            end
        end
    end

    describe '#any?' do
        context 'when there are no platforms' do
            it 'returns false' do
                expect(platforms.any?).to be_falsey
            end
        end
        context 'when there are platforms' do
            it 'returns true' do
                platforms << :asp
                expect(platforms.any?).to be_truthy
            end
        end
    end

    describe '#clear' do
        it 'clears the global platform DB' do
            platforms << :unix
            expect(platforms.empty?).to be_falsey
            platforms.clear
            expect(platforms.empty?).to be_truthy
        end
    end

    describe '#dup' do
        it 'creates a copy' do
            platforms << :unix
            cplatforms = platforms.dup
            cplatforms << :php

            expect(cplatforms.sort).to eq([:unix, :php].sort)
            expect(platforms.to_a).to eq([:unix])
        end
    end
end
