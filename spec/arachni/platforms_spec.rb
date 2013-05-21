require 'spec_helper'

describe Arachni::Platforms do

    after(:each) { described_class.reset }

    let(:platforms) { described_class.new }

    it 'is Enumerable' do
        platforms.is_a? Enumerable
    end

    describe '.set' do
        it 'set the global platform fingerprints' do
            described_class.set 'stuff'
            described_class.all.should == 'stuff'
        end
    end

    describe '.reset' do
        it 'clears the global platform fingerprints' do
            described_class.set 'stuff'
            described_class.reset
            described_class.all.should be_empty
        end

        it 'returns self' do
            described_class.reset.should == described_class
        end
    end

    describe '.fingerprint' do
        it 'runs all fingerprinters against the given page' do
            page = Arachni::Page.new( url: 'http://stuff.com/blah.php' )

            page.platforms.should be_empty
            described_class.fingerprint page
            page.platforms.sort.should == [:unix, :apache].sort

            described_class[page.url].should == page.platforms
        end

        it 'returns the given page' do
            page = Arachni::Page.new( url: 'http://stuff.com/' )
            described_class.fingerprint( page ).should == page
        end
    end

    describe '.[]' do
        it 'ignores query parameters in the key URL' do
            base = 'http://stuff.com/'
            uri  = base + '?stuff=here'

            platforms << :unix << :jsp
            described_class[uri] = platforms
            described_class[uri].should == platforms
            described_class[base].should == described_class[uri]
        end

        it 'retrieves the platforms for the given URI' do
            described_class['http://stuff.com'] = platforms
            described_class['http://stuff.com'].should == platforms
        end

        it "defaults to a #{described_class} instance" do
            described_class['http://blahblah.com/'].should be_kind_of described_class
            described_class['http://blahblah.com/'].should be_empty
            described_class['http://blahblah.com/'] << :unix
            described_class['http://blahblah.com/'].should be_any
        end
    end

    describe '.[]=' do
        it 'ignores query parameters in the key URL' do
            base = 'http://stuff.com/'
            uri  = base + '?stuff=here'

            platforms << :unix << :jsp
            described_class[uri] = platforms
            described_class[uri].should == platforms
            described_class[base].should == described_class[uri]
        end

        it 'set the platforms for the given URI' do
            platforms = [:unix, :jsp]
            described_class['http://stuff.com'] = platforms
            described_class.all.values.first.sort.should == platforms.sort
        end

        it "converts the value to a #{described_class}" do
            platforms = [:unix, :jsp]
            described_class['http://stuff.com'] = platforms
            described_class.all.values.first.should be_kind_of described_class
        end

        context 'when invalid platforms are given' do
            it 'raises Arachni::Platforms::Error::Invalid' do
                expect {
                    described_class['http://stuff.com'] = [:stuff]
                }.to raise_error Arachni::Platforms::Error::Invalid
            end
        end
    end

    describe '.update' do
        it 'updates the platforms for the given URI' do
            platforms = [:unix, :jsp]
            described_class['http://stuff.com'] = platforms

            described_class.update( 'http://stuff.com', [:pgsql] )
            described_class.all.values.first.sort.should == (platforms | [:pgsql]).sort
        end

        context 'when invalid platforms are given' do
            it 'raises Arachni::Platforms::Error::Invalid' do
                expect {
                    described_class.update( 'http://stuff.com', [:stuff] )
                }.to raise_error Arachni::Platforms::Error::Invalid
            end
        end
    end

    describe '#empty?' do
        context 'when there are no fingerprints' do
            it 'returns true' do
                described_class.empty?.should be_true
            end
        end
        context 'when there are platforms' do
            it 'returns false' do
                described_class['http://stuff.com'] << :unix
                described_class.empty?.should be_false
            end
        end
    end

    describe '#any?' do
        context 'when there are no platforms' do
            it 'returns false' do
                described_class.any?.should be_false
            end
        end
        context 'when there are platforms' do
            it 'returns true' do
                described_class['http://stuff.com'] << :unix
                described_class.any?.should be_true
            end
        end
    end

    describe '.all' do
        it 'returns all platforms per URL' do
            described_class['http://stuff.com'] << :unix
            described_class.all.should be_any
            described_class.all.should be_kind_of Hash
        end
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

    describe '#os_flat' do
        it 'returns a flat list of supported operating systems' do
            platforms.os_flat.sort.should ==
                [:unix, :linux, :bsd, :freebsd, :openbsd, :solaris, :windows].sort
        end
    end

    describe '#all' do
        it 'returns all supported platforms' do
            platforms.all.sort.should ==
                (platforms.os_flat + described_class::DB + described_class::SERVERS +
                    described_class::LANGUAGES + described_class::FRAMEWORKS).sort
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

        context 'when a parent OS has been specified' do
            it 'includes all children OS flavors' do
                applicable_data = {
                    linux:   [ 'Linux stuff' ],
                    freebsd: [ 'FreeBSD stuff' ],
                    php:     [ 'PHP stuff' ]
                }
                data = applicable_data.merge( windows: [ 'Windows stuff' ] )

                platforms << :unix << :php

                platforms.pick( data ).should == applicable_data
            end

            context 'and specific OS flavors are specified' do
                it 'removes parent OS types' do
                    applicable_data = {
                        # This should not be in the picked data.
                        unix:    [ 'Generic *nix stuff' ],

                        # This should not be in the picked data.
                        bsd:     [ 'BSD stuff' ],

                        linux:   [ 'Linux stuff' ],
                        freebsd: [ 'FreeBSD stuff' ],
                        php:     [ 'PHP stuff' ]
                    }
                    data = applicable_data.merge( windows: [ 'Windows stuff' ] )

                    platforms << :bsd << :linux << :php << :unix << :freebsd << :openbsd

                    applicable_data.delete( :unix )
                    applicable_data.delete( :bsd )

                    platforms.pick( data ).should == applicable_data
                end
            end
        end

        context 'when invalid platforms are given' do
            it 'raises Arachni::Platforms::Error::Invalid' do
                expect {
                    platforms.pick(  { blah: 1, unix: 'stuff' } )
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
