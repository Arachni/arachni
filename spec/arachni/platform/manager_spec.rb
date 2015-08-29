require 'spec_helper'

describe Arachni::Platform::Manager do

    before(:each) { Arachni::Options.reset }
    after(:each) { described_class.reset }

    let(:platforms) { described_class.new }
    let(:http) { Arachni::HTTP::Client }

    def page
        Arachni::Options.do_not_fingerprint
        page = Arachni::Page.from_url( "#{web_server_url_for( :auditor )}/s.php" )
        Arachni::Options.fingerprint
        page
    end

    def binary_page
        Arachni::Options.do_not_fingerprint
        page = Arachni::Page.from_url( "#{web_server_url_for( :auditor )}/binary" )
        Arachni::Options.fingerprint
        page
    end

    it 'is Enumerable' do
        platforms.is_a? Enumerable
    end

    it "caches up to #{described_class::PLATFORM_CACHE_SIZE} entries" do
        url = 'http://test/'

        (2 * described_class::PLATFORM_CACHE_SIZE).times do |i|
            described_class["#{url}/#{i}"] << :unix
        end

        expect(described_class.size).to eq(described_class::PLATFORM_CACHE_SIZE)
    end

    describe '.set' do
        it 'set the global platform fingerprints' do
            described_class.set( 'http://test/' => [:unix] )
            expect(described_class['http://test/']).to include :unix
        end
    end

    describe '.reset' do
        it 'clears the global platform fingerprints' do
            described_class.set( 'http://test/' => [:unix] )
            described_class.reset
            expect(described_class).to be_empty
        end

        it 'returns self' do
            expect(described_class.reset).to eq(described_class)
        end
    end

    describe '.include?' do
        context 'when the list includes the given key' do
            it 'returns true' do
                url = 'http://stuff/'
                described_class[url] << :unix
                expect(described_class).to include url
            end
        end

        context 'when the list does not include the given key' do
            it 'returns true' do
                url = 'http://stuff/'
                expect(described_class).not_to include url
            end
        end
    end

    describe '.clear' do
        it 'clear all platforms' do
            described_class.update( 'http://test/', [:unix, :java] )
            expect(described_class).to be_any
            described_class.clear
            expect(described_class).to be_empty
        end
    end

    describe '.fingerprint?' do
        Arachni::Options.do_not_fingerprint
        page = Arachni::Page.from_url( "#{web_server_url_for( :auditor )}/s.php" )
        Arachni::Options.fingerprint
        page

        [page, page.response].each do |resource|
            context "when given a #{resource.class}" do
                context 'when Options.fingerprint is set to' do
                    context 'true' do
                        context 'and it is text based' do
                            context 'and has not yet been fingerprinted' do
                                context 'and is within scope' do
                                    context 'and has a #code of 200' do
                                        it 'returns true' do
                                            expect(described_class.fingerprint?( page )).to be_truthy
                                        end
                                    end

                                    context 'and has a non-200 #code' do
                                        it 'returns false' do
                                            allow(page).to receive(:code) { 404 }
                                            expect(described_class.fingerprint?( page )).to be_falsey
                                        end
                                    end
                                end

                                context 'and is out of scope' do
                                    it 'returns false' do
                                        Arachni::Options.scope.exclude_path_patterns << /s/
                                        expect(described_class.fingerprint?( page )).to be_falsey
                                    end
                                end
                            end

                            context 'and the resource has already been fingerprinted' do
                                it 'returns false' do
                                    described_class[page.url] << :unix
                                    expect(described_class.fingerprint?( page )).to be_falsey
                                end
                            end
                        end
                        context 'and it is not text based' do
                            it 'returns false' do
                                expect(described_class.fingerprint?( binary_page )).to be_falsey
                            end
                        end
                    end

                    context 'false' do
                        it 'returns false' do
                            p = page
                            Arachni::Options.do_not_fingerprint
                            expect(described_class.fingerprint?( p )).to be_falsey
                        end
                    end
                end
            end
        end
    end

    describe '.fingerprint' do
        it 'runs all fingerprinters against the given page' do
            described_class.fingerprint page
            expect(page.platforms.sort).to eq([:php].sort)

            expect(described_class[page.url]).to eq(page.platforms)
        end

        it 'returns the given page' do
            expect(described_class.fingerprint( page )).to eq(page)
        end

        context 'even when no platforms have been identified' do
            it 'marks the page as fingerprinted' do
                page = Arachni::Page.from_url( web_server_url_for( :auditor ) )

                described_class.fingerprint( page )
                expect(page.platforms).to be_empty
                expect(described_class.fingerprint?( page )).to be_falsey
            end
        end
    end

    describe '.[]' do
        it 'ignores query parameters in the key URL' do
            base = 'http://stuff.com/'
            uri  = base + '?stuff=here'

            platforms << :unix << :java
            described_class[uri] = platforms
            expect(described_class[uri]).to eq(platforms)
            expect(described_class[base]).to eq(described_class[uri])
        end

        it 'retrieves the platforms for the given URI' do
            described_class['http://stuff.com'] = platforms
            expect(described_class['http://stuff.com']).to eq(platforms)
        end

        it "defaults to a #{described_class} instance" do
            expect(described_class['http://blahblah.com/']).to be_kind_of described_class
            expect(described_class['http://blahblah.com/']).to be_empty
            described_class['http://blahblah.com/'] << :unix
            expect(described_class['http://blahblah.com/']).to be_any
        end
    end

    describe '.[]=' do
        it 'ignores query parameters in the key URL' do
            base = 'http://stuff.com/'
            uri  = base + '?stuff=here'

            platforms << :unix << :java

            described_class[uri] = platforms
            expect(described_class[uri]).to eq(platforms)
            expect(described_class[base]).to eq(described_class[uri])
        end

        it 'set the platforms for the given URI' do
            platforms = [:unix, :java]
            described_class['http://stuff.com'] = platforms

            platforms.each do |platform|
                expect(described_class['http://stuff.com']).to include platform
            end
        end

        it "converts the value to a #{described_class}" do
            platforms = [:unix, :java]
            described_class['http://stuff.com'] = platforms
            platforms.each do |platform|
                expect(described_class['http://stuff.com']).to be_kind_of described_class
            end
        end

        it 'includes Options.platforms' do
            Arachni::Options.platforms = [:ruby, :windows]
            platforms = [:unix, :java]

            described_class['http://stuff.com'] = platforms

            expect(described_class['http://stuff.com'].sort).to eq(
                (Arachni::Options.platforms | platforms).sort
            )
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
                described_class.update( 'http://test.com/', [:java] )
                expect(described_class['http://test.com/'].sort).to eq([:unix, :java].sort)
            end
        end
        context 'with invalid platforms' do
            it 'raises Arachni::Platform::Error::Invalid' do
                expect {
                    described_class.update( 'http://test.com/', [:blah] )
                }.to raise_error Arachni::Platform::Error::Invalid
            end
        end
    end

    describe '.valid' do
        it 'returns all platforms' do
            expect(described_class.valid.to_a).to eq(described_class::PLATFORM_NAMES.keys)
        end
    end

    describe '.valid?' do
        context 'when the given platforms are' do
            context 'valid' do
                it 'returns true' do
                    described_class.valid.each do |platform|
                        expect(described_class.valid?( platform )).to be_truthy
                    end

                    expect(described_class.valid?( described_class.valid.to_a )).to be_truthy
                end
            end

            context 'invalid' do
                it 'returns false' do
                    expect(described_class.valid?( :stuff )).to be_falsey
                    expect(described_class.valid?( described_class.valid.to_a + [:stuff] )).to be_falsey
                end
            end
        end
    end

    describe '#new_from_options' do
        it 'includes Options.platforms' do
            Arachni::Options.platforms = [:ruby, :windows]
            platforms = [:unix, :java]

            expect(described_class.new_from_options( platforms ).sort).to eq(
                (platforms | Arachni::Options.platforms).sort
            )
        end
    end

    describe '#initialize' do
        it 'initializes the manager with the given platforms' do
            platforms = [:unix, :java, :mysql].sort
            expect(described_class.new( platforms ).sort).to eq(platforms)
        end
    end

    describe '#os' do
        it 'returns the operating system list' do
            expect(platforms.os).to be_kind_of Arachni::Platform::List
        end
    end

    describe '#db' do
        it 'returns the database list' do
            expect(platforms.db).to be_kind_of Arachni::Platform::List
        end
    end

    describe '#servers' do
        it 'returns the server list' do
            expect(platforms.servers).to be_kind_of Arachni::Platform::List
            expect(platforms.servers.valid.sort).to eq(described_class::SERVERS.sort)
        end
    end

    describe '#languages' do
        it 'returns the language list' do
            expect(platforms.languages).to be_kind_of Arachni::Platform::List
            expect(platforms.languages.valid.sort).to eq(described_class::LANGUAGES.sort)
        end
    end

    describe '#frameworks' do
        it 'returns the framework list' do
            expect(platforms.frameworks).to be_kind_of Arachni::Platform::List
            expect(platforms.frameworks.valid.sort).to eq(described_class::FRAMEWORKS.sort)
        end
    end

    describe '#fullname' do
        it 'returns the full name for the given platform' do
            platforms.valid.each do |platform|
                expect(platforms.fullname( platform )).to be_kind_of String
            end
        end
    end

    describe '#pick' do
        it 'returns only data relevant to the applicable platforms' do
            applicable_data = {
                unix: [ 'UNIX stuff' ],
                php:  [ 'PHP stuff' ]
            }
            data = applicable_data.merge( java:    [ 'JSP stuff' ],
                                          windows: [ 'Windows stuff' ] )

            platforms << :unix << :php
            expect(platforms.pick( data )).to eq(applicable_data)
        end

        it 'only enforces platform filtering for non-empty platform lists' do
            applicable_data = {
                linux: [ 'UNIX stuff' ],
                bsd:   [ 'UNIX stuff' ],
                php:   [ 'PHP stuff' ],
                java:  [ 'JSP stuff' ]
            }
            data = applicable_data.merge( windows: [ 'Windows stuff' ] )

            platforms << :unix
            expect(platforms.pick( data )).to eq(applicable_data)
        end

        context 'when a parent OS has been specified' do
            it 'includes all children OS flavors' do
                applicable_data = {
                    linux:   [ 'Linux stuff' ],
                    solaris: [ 'Solaris stuff' ],
                    php:     [ 'PHP stuff' ]
                }
                data = applicable_data.merge( windows: [ 'Windows stuff' ] )

                platforms << :unix

                expect(platforms.pick( data )).to eq(applicable_data)
            end

            context 'and specific OS flavors are specified' do
                it 'removes parent OS types' do
                    applicable_data = {
                        # This should not be in the picked data.
                        unix:    [ 'Generic *nix stuff' ],


                        linux:   [ 'Linux stuff' ],
                        php:     [ 'PHP stuff' ]
                    }
                    data = applicable_data.merge( java: [ 'JSP stuff' ],
                                                  windows: [ 'Windows stuff' ] )

                    platforms << :linux << :php << :unix

                    applicable_data.delete( :unix )
                    applicable_data.delete( :bsd )

                    expect(platforms.pick( data )).to eq(applicable_data)
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
            expect(platforms.valid.sort).to eq(
                [:unix, :linux, :bsd, :solaris, :windows,
                 :db2, :emc, :informix, :interbase, :mssql, :mysql,
                 :oracle, :firebird, :maxdb, :pgsql, :sqlite, :apache, :iis, :nginx,
                 :tomcat, :asp, :aspx, :java, :perl, :php, :python, :ruby, :rack,
                 :sybase, :frontbase, :ingres, :hsqldb, :access, :jetty, :mongodb,
                 :aix, :sql, :nosql, :aspx_mvc, :rails, :django, :gunicorn, :cakephp,
                 :cherrypy, :jsf, :symfony, :nette].sort
            )
        end
    end

    describe '#each' do
        it 'iterates over all applicable platforms' do
            included_platforms = platforms.update( [:unix, :java] ).sort
            expect(included_platforms).to be_any

            iterated = []
            platforms.each do |platform|
                iterated << platform
            end

            expect(iterated.sort).to eq(included_platforms)
        end
    end

    describe '#clear' do
        it 'clear the platforms' do
            platforms.update( [:unix, :java] )
            expect(platforms).to be_any
            platforms.clear
            expect(platforms).to be_empty
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

end
