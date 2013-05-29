require 'spec_helper'

describe Arachni::Platform::Manager do

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
            it 'raises Arachni::Platform::Error::Invalid' do
                expect {
                    described_class['http://stuff.com'] = [:stuff]
                }.to raise_error Arachni::Platform::Error::Invalid
            end
        end
    end

    describe '.update' do
        context 'with valid platforms' do
            it 'updates self with the given platforms' do
                described_class['http://test.com/'] << :unix
                described_class['http://test.com/'].update( [:jsp] )
                described_class['http://test.com/'].sort.should == [:unix, :jsp].sort
            end
        end
        context 'with invalid platforms' do
            it 'raises Arachni::Platform::Error::Invalid' do
                expect {
                    described_class['http://test.com/'].update( [:blah] )
                }.to raise_error Arachni::Platform::Error::Invalid
            end
        end
    end

    describe '.all' do
        it 'returns the raw internal DB of fingerprints' do
            described_class.all.size.should == 0
            described_class['http://test.com/'] << :unix
            described_class.all.size.should == 1
            described_class.all.first.last.should be_kind_of described_class
        end
    end

    describe '.light' do
        it 'returns a light representation of the internal DB of fingerprints' do
            described_class['http://test.com/'] << :unix
            described_class.light.first.last.should == [:unix]
        end
    end

    describe '.load_light' do
        it 'loads a DB from a light representation' do
            described_class['http://test.com/'] << :unix
            light = described_class.light
            described_class.reset
            described_class.all.should be_empty

            described_class.load_light light
            described_class.all.should be_any
            described_class['http://test.com/'].should include :unix
        end
    end

    describe '#initialize' do
        it 'initializes the manager with the given platforms' do
            platforms = [:unix, :jsp, :mysql].sort
            described_class.new( platforms ).sort.should == platforms
        end
    end

    describe '#os' do
        it 'returns the operating system list' do
            platforms.os.should be_kind_of Arachni::Platform::List
        end
    end

    describe '#db' do
        it 'returns the database list' do
            platforms.db.should be_kind_of Arachni::Platform::List
            platforms.db.valid.sort.should == described_class::DB.sort
        end
    end

    describe '#servers' do
        it 'returns the server list' do
            platforms.servers.should be_kind_of Arachni::Platform::List
            platforms.servers.valid.sort.should == described_class::SERVERS.sort
        end
    end

    describe '#languages' do
        it 'returns the language list' do
            platforms.languages.should be_kind_of Arachni::Platform::List
            platforms.languages.valid.sort.should == described_class::LANGUAGES.sort
        end
    end

    describe '#frameworks' do
        it 'returns the framework list' do
            platforms.frameworks.should be_kind_of Arachni::Platform::List
            platforms.frameworks.valid.sort.should == described_class::FRAMEWORKS.sort
        end
    end

    describe '#pick' do
        it 'returns only data relevant to the applicable platforms' do
            applicable_data = {
                unix: [ 'UNIX stuff' ],
                php:  [ 'PHP stuff' ]
            }
            data = applicable_data.merge( jsp:  [ 'JSP stuff' ],
                                          windows: [ 'Windows stuff' ] )

            platforms << :unix << :php
            platforms.pick( data ).should == applicable_data
        end

        it 'only enforces platform filtering for non-empty platform lists' do
            applicable_data = {
                linux: [ 'UNIX stuff' ],
                bsd:   [ 'UNIX stuff' ],
                php:   [ 'PHP stuff' ],
                jsp:   [ 'JSP stuff' ]
            }
            data = applicable_data.merge( windows: [ 'Windows stuff' ] )

            platforms << :unix
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

                platforms << :unix

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
                    data = applicable_data.merge( jsp: [ 'JSP stuff' ],
                                                  windows: [ 'Windows stuff' ] )

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
                }.to raise_error Arachni::Platform::Error::Invalid
            end
        end
    end

    describe '#valid' do
        it 'returns all valid platforms' do
            platforms.valid.sort.should ==
                [:unix, :linux, :bsd, :freebsd, :openbsd, :solaris, :windows,
                 :coldfusion, :db2, :emc, :informix, :interbase, :mssql, :mysql,
                 :oracle, :pgsql, :sqlite, :apache, :iis, :nginx, :tomcat, :asp,
                 :aspx, :jsp, :perl, :php, :python, :ruby, :rack].sort
        end
    end

    describe '#each' do
        it 'iterates over all applicable platforms' do
            included_platforms = platforms.update( [:unix, :jsp] ).sort
            included_platforms.should be_any

            iterated = []
            platforms.each do |platform|
                iterated << platform
            end

            iterated.sort.should == included_platforms
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

end
