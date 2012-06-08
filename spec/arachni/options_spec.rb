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
            @opts.redundant.should == { /calendar\.php/ => 5 }

            new_format = { 'regexp' => 39 }
            @opts.redundant = new_format
            @opts.redundant.should == { /regexp/ => 39 }

            @opts.redundant = redundants
            @opts.redundant.should == {
                /calendar\.php/ => 5,
                /gallery\.php/ => 3
            }
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

    describe '#serialize' do
        it 'should return an one-line serialized version of self' do
            s = @opts.serialize
            s.is_a?( String ).should be_true
            s.include?( "\n" ).should be_false
        end
    end

    describe '#unserialize' do
        it 'should unserialize the return value of #serialize' do
            s = @opts.serialize
            @opts.unserialize( s ).should == @opts
        end
    end

    describe '#save' do
        it 'should dump a serialized version of self to a file' do
            f = 'options'
            @opts.save( f )

            raised = false
            begin
                File.delete( f )
            rescue
                raised = true
            end
            raised.should be_false
        end
    end

    describe '#load' do
        it 'should dump a serialized version of self to a file (without the directory data)' do
            f = 'options'
            @opts.save( f )

            @opts.dir = nil
            @opts.load( f ).should == @opts

            raised = false
            begin
                File.delete( f )
            rescue
                raised = true
            end
            raised.should be_false
        end
    end

    describe '#to_hash' do
        it 'should convert self to a hash' do
            h = @opts.to_hash
            h.is_a?( Hash ).should be_true

            h.each { |k, v| @opts.instance_variable_get( "@#{k}".to_sym ).should == v }
        end
    end

    describe '#to_h' do
        it 'should be aliased to to_hash' do
            @opts.to_hash.should == @opts.to_h
        end
    end

    describe '#==' do
        context 'when both objects are equal' do
            it 'should return true' do
                @opts.should == @opts
            end
        end
        context 'when objects are not equal' do
            it 'should return true' do
                @opts.should_not == @opts.load( @opts.save( 'test_opts' ) )
                File.delete( 'test_opts' )
            end
        end
    end

    describe '#merge!' do
        context 'when the param is a' do
            context Arachni::Options do
                it 'should merge self with the passed object' do
                    opts = @opts.load( @opts.save( 'test_opts' ) )
                    File.delete( 'test_opts' )

                    opts.nickname = 'billybob'
                    @opts.nickname.should be_nil
                    @opts.merge!( opts )
                    @opts.nickname.should == 'billybob'
                end
            end
            context Hash do
                it 'should merge self with the passed object' do
                    @opts.depth_limit = 20
                    @opts.depth_limit.should == 20

                    @opts.merge!( { depth_limit: 10 } )
                    @opts.depth_limit.should == 10
                end
            end
        end

        it 'should skip nils and empty Arrays or Hashes' do
            @opts.exclude = 'test'
            @opts.merge!( { 'exclude' => [] } )
            @opts.exclude.should == [ /test/ ]

            @opts.datastore = { 'test' => :val }
            @opts.merge!( { 'datastore' => {} } )
            @opts.datastore.should == { 'test' => :val }

            @opts.merge!( { 'datastore' => nil } )
            @opts.datastore.should == { 'test' => :val }
        end
    end

end
