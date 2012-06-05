require_relative '../spec_helper'

describe Arachni::Options do
    before( :each ) do
        @opts = Arachni::Options.instance.reset
        @utils = Arachni::Module::Utilities
    end

    describe '#url' do
        it 'should normalize its param and set it as the target URL' do
            @opts.url = 'http://test.com/my path'
            @opts.url.should == @utils.normalize_url( @opts.url )
        end

        context 'when a relative URL is passed' do
            it 'should throw an exception' do
                raised = false
                begin
                    @opts.url = '/my path'
                rescue
                    raised = true
                end
                raised.should be_true
            end
        end

        context 'when a URL with invalid scheme is passed' do
            it 'should throw an exception' do
                raised = false
                begin
                    @opts.url = 'httpss://test.com/my path'
                rescue
                    raised = true
                end
                raised.should be_true
            end
        end
    end

    describe '#set' do
        context 'when keys are strings' do
            it 'should set options by hash' do
                opts = {
                    'url'       => 'http://blah.com',
                    'exclude'   => [ 'exclude me' ],
                    'include'   => [ 'include me' ],
                    'redundant' => { 'regexp' => 'redundant', 'count' => 3 },
                    'datastore' => { key: 'val' }
                }
                @opts.set( opts )

                @opts.url.to_s.should == @utils.normalize_url( opts['url'] )
                @opts.exclude.should == [/exclude me/]
                @opts.include.should == [/include me/]
                @opts.datastore.should == opts['datastore']
            end
        end

        context 'when keys are symbols' do
            it 'should set options by hash' do
                opts = {
                    url:       'http://blah2.com',
                    exclude:   ['exclude me2'],
                    include:   ['include me2'],
                    redundant: { 'regexp' => 'redundant2', 'count' => 4 },
                    datastore: { key2: 'val2' }
                }
                @opts.set( opts )

                @opts.url.to_s.should == @utils.normalize_url( opts[:url] )
                @opts.exclude.should == [/exclude me2/]
                @opts.include.should == [/include me2/]
                @opts.datastore.should == opts[:datastore]
            end
        end
    end

    describe '#exclude_cookies=' do
        it 'should convert its param to an array of strings' do
            cookies = %w(my_cookie my_other_cookie)

            @opts.exclude_cookies = cookies.first
            @opts.exclude_cookies.should == [cookies.first]

            @opts.exclude_cookies = cookies
            @opts.exclude_cookies.should == cookies
        end
    end

    describe '#exclude_vectors=' do
        it 'should convert its param to an array of strings' do
            vectors = %w(my_vector my_other_vector)

            @opts.exclude_vectors = vectors.first
            @opts.exclude_vectors.should == [vectors.first]

            @opts.exclude_vectors = vectors
            @opts.exclude_vectors.should == vectors
        end
    end

    describe '#mods=' do
        it 'should convert its param to an array of strings' do
            mods = %w(my_mods my_other_mods)

            @opts.mods = mods.first
            @opts.mods.should == [mods.first]

            @opts.mods = mods
            @opts.mods.should == mods
        end
    end

    describe '#restrict_paths=' do
        it 'should convert its param to an array of strings' do
            restrict_paths = %w(my_restrict_paths my_other_restrict_paths)

            @opts.restrict_paths = restrict_paths.first
            @opts.restrict_paths.should == [restrict_paths.first]

            @opts.restrict_paths = restrict_paths
            @opts.restrict_paths.should == restrict_paths
        end
    end

    describe '#extend_paths=' do
        it 'should convert its param to an array of strings' do
            extend_paths = %w(my_extend_paths my_other_extend_paths)

            @opts.extend_paths = extend_paths.first
            @opts.extend_paths.should == [extend_paths.first]

            @opts.extend_paths = extend_paths
            @opts.extend_paths.should == extend_paths
        end
    end

    describe '#include=' do
        it 'should convert its param to an array of strings' do
            include = %w(my_include my_other_include)

            @opts.include = /test/
            @opts.include.should == [/test/]

            @opts.include = include.first
            @opts.include.should == [Regexp.new( include.first )]

            @opts.include = include
            @opts.include.should == include.map { |p| Regexp.new( p ) }
        end
    end

    describe '#exclude=' do
        it 'should convert its param to an array of strings' do
            exclude = %w(my_exclude my_other_exclude)

            @opts.exclude = /test/
            @opts.exclude.should == [/test/]

            @opts.exclude = exclude.first
            @opts.exclude.should == [Regexp.new( exclude.first )]

            @opts.exclude = exclude
            @opts.exclude.should == exclude.map { |p| Regexp.new( p ) }
        end
    end

    describe '#lsmod=' do
        it 'should convert its param to an array of strings' do
            lsmod = %w(my_lsmod my_other_lsmod)

            @opts.lsmod = /test/
            @opts.lsmod.should == [/test/]

            @opts.lsmod = lsmod.first
            @opts.lsmod.should == [Regexp.new( lsmod.first )]

            @opts.lsmod = lsmod
            @opts.lsmod.should == lsmod.map { |p| Regexp.new( p ) }
        end
    end

    describe '#lsrep=' do
        it 'should convert its param to an array of strings' do
            lsrep = %w(my_lsrep my_other_lsrep)

            @opts.lsrep = /test/
            @opts.lsrep.should == [/test/]

            @opts.lsrep = lsrep.first
            @opts.lsrep.should == [Regexp.new( lsrep.first )]

            @opts.lsrep = lsrep
            @opts.lsrep.should == lsrep.map { |p| Regexp.new( p ) }
        end
    end

    describe '#lsplug=' do
        it 'should convert its param to an array of strings' do
            lsplug = %w(my_lsplug my_other_lsplug)

            @opts.lsplug = /test/
            @opts.lsplug.should == [/test/]

            @opts.lsplug = lsplug.first
            @opts.lsplug.should == [Regexp.new( lsplug.first )]

            @opts.lsplug = lsplug
            @opts.lsplug.should == lsplug.map { |p| Regexp.new( p ) }
        end
    end

    describe '#redundant=' do
        it 'should convert its param to properly typed filters' do
             redundants = [
                {
                    'regexp'    => /calendar\.php/,
                    'count'     => 5
                },
                {
                    'regexp'    => 'gallery\.php',
                    'count'     => '3'
                }
            ]

            @opts.redundant = redundants.first
            @opts.redundant.should == [redundants.first]

            @opts.redundant = redundants
            @opts.redundant.should == [
                {
                    'regexp'    => /calendar\.php/,
                    'count'     => 5
                },
                {
                    'regexp'    => /gallery\.php/,
                    'count'     => 3
                }
            ]
        end
    end

    describe '#datastore=' do
        it 'should try to cast its param to a Hash' do
            @opts.datastore = [[ :k, 'val' ]]
            @opts.datastore.should == { k: 'val' }

            @opts.datastore = { key: 'value' }
            @opts.datastore.should == { key: 'value' }
        end
    end

end
