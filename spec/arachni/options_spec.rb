require 'spec_helper'

describe Arachni::Options do
    before( :each ) do
        ENV['ARACHNI_FRAMEWORK_LOGDIR'] = nil
        @opts = Arachni::Options.instance.reset
        @utils = Arachni::Module::Utilities
    end

    it 'proxies missing class methods to instance methods' do
        url = 'http://test.com/'
        Arachni::Options.url.should_not == url
        Arachni::Options.url = url
        Arachni::Options.url.should == url
    end

    describe "#dir['logs']" do
        context 'when the ARACHNI_FRAMEWORK_LOGDIR environment variable' do
            context 'has been set' do
                it 'returns its value' do
                    ENV['ARACHNI_FRAMEWORK_LOGDIR'] = 'test'
                    described_class.reset
                    described_class.dir['logs'].should == 'test/'
                end
            end
            context 'has not been set' do
                it 'returns the default location' do
                    described_class.dir['logs'].should == "#{described_class.dir['root']}logs/"
                end
            end
        end
    end

    describe '#grid?' do
        describe 'when the option has been enabled' do
            context 'via #grid=' do
                it 'returns true' do
                    Arachni::Options.grid = true
                    Arachni::Options.grid?.should be_true
                end
            end

            context 'via #grid_mode=' do
                it 'returns true' do
                    Arachni::Options.grid_mode = :balance
                    Arachni::Options.grid?.should be_true
                end
            end
        end
        describe 'when the option has been disabled' do
            context 'via #grid=' do
                it 'returns false' do
                    Arachni::Options.grid = false
                    Arachni::Options.grid?.should be_false
                end
            end

            context 'via #grid_mode=' do
                it 'returns false' do
                    Arachni::Options.grid_mode = false
                    Arachni::Options.grid?.should be_false
                end
            end
        end
        describe 'by default' do
            it 'returns false' do
                Arachni::Options.grid?.should be_false
            end
        end
    end

    describe '#grid=' do
        context true do
            it 'is a shorthand for #grid_mode = :balance' do
                Arachni::Options.grid = true
                Arachni::Options.grid_mode.should == :balance
            end
        end
    end

    describe '#grid_mode=' do
        context 'when given' do
            context String do
                it 'converts it to Symbol and sets the option' do
                    Arachni::Options.grid_mode = 'balance'
                    Arachni::Options.grid_mode.should == :balance
                end
            end

            context Symbol do
                it 'sets the option' do
                    Arachni::Options.grid_mode = :aggregate
                    Arachni::Options.grid_mode.should == :aggregate
                end
            end

            context 'an invalid option' do
                it 'raises ArgumentError' do
                    expect { Arachni::Options.grid_mode = :stuff }.to raise_error ArgumentError
                end
            end
        end
    end

    describe '#grid_aggregate?' do
        context 'when in :aggregate mode' do
            it 'returns true' do
                Arachni::Options.grid_aggregate?.should be_false
                Arachni::Options.grid_mode = :aggregate
                Arachni::Options.grid_aggregate?.should be_true
            end
        end
        context 'when in :balance mode' do
            it 'returns false' do
                Arachni::Options.grid_aggregate?.should be_false
                Arachni::Options.grid_mode = :balance
                Arachni::Options.grid_aggregate?.should be_false
            end
        end
    end

    describe '#grid_balance?' do
        context 'when in :balance mode' do
            it 'returns true' do
                Arachni::Options.grid_balance?.should be_false
                Arachni::Options.grid_mode = :balance
                Arachni::Options.grid_balance?.should be_true
            end
        end
        context 'when in :balance mode' do
            it 'returns false' do
                Arachni::Options.grid_balance?.should be_false
                Arachni::Options.grid_mode = :aggregate
                Arachni::Options.grid_balance?.should be_false
            end
        end
    end

    describe '#no_protocol_for_url' do
        it 'allows URLs without a protocol' do
            trigger = proc { Arachni::Options.url = 'stuff:80' }

            raised = false
            begin
                trigger.call
            rescue Arachni::Error
                raised = true
            end
            raised.should be_true

            raised = false
            begin
                trigger.call
            rescue Arachni::Options::Error
                raised = true
            end
            raised.should be_true

            raised = false
            begin
                trigger.call
            rescue Arachni::Options::Error::InvalidURL
                raised = true
            end
            raised.should be_true

            Arachni::Options.no_protocol_for_url
            Arachni::Options.url = 'stuff:80'
            Arachni::Options.url.should == 'stuff:80'
        end
    end

    describe '#min_pages_per_instance=' do
        it 'forces its argument to an Integer' do
            Arachni::Options.min_pages_per_instance = '55'
            Arachni::Options.min_pages_per_instance.should == 55
        end
    end

    describe '#max_slaves=' do
        it 'forces its argument to an Integer' do
            Arachni::Options.max_slaves = '56'
            Arachni::Options.max_slaves.should == 56
        end
    end

    describe '#user_agent' do
        it "defaults to Arachni/v#{Arachni::VERSION}" do
            Arachni::Options.user_agent.should == 'Arachni/v' + Arachni::VERSION.to_s
        end
    end

    describe '#http_timeout' do
        it "defaults to 50000" do
            Arachni::Options.http_timeout.should == 50000
        end
    end

    describe '#https_only?' do
        describe 'when the option has been enabled' do
            it 'returns true' do
                Arachni::Options.https_only = true
                Arachni::Options.https_only?.should be_true
            end
        end
        describe 'when the option has been disabled' do
            it 'returns false' do
                Arachni::Options.https_only = false
                Arachni::Options.https_only?.should be_false
            end
        end
        describe 'by default' do
            it 'returns false' do
                Arachni::Options.https_only?.should be_false
            end
        end
    end

    describe '#auto_redundant?' do
        describe 'when the option has been enabled' do
            it 'returns true' do
                Arachni::Options.auto_redundant = 10
                Arachni::Options.auto_redundant?.should be_true
            end
        end
        describe 'when the option has been disabled' do
            it 'returns false' do
                Arachni::Options.auto_redundant = nil
                Arachni::Options.auto_redundant?.should be_false
            end
        end
        describe 'by default' do
            it 'returns false' do
                Arachni::Options.auto_redundant?.should be_false
            end
        end
    end

    describe '#exclude_binaries?' do
        describe 'when the option has been enabled' do
            it 'returns true' do
                Arachni::Options.exclude_binaries = true
                Arachni::Options.exclude_binaries?.should be_true
            end
        end
        describe 'when the option has been disabled' do
            it 'returns false' do
                Arachni::Options.exclude_binaries = false
                Arachni::Options.exclude_binaries?.should be_false
            end
        end
        describe 'by default' do
            it 'returns false' do
                Arachni::Options.exclude_binaries?.should be_false
            end
        end
    end

    describe '#do_not_fingerprint' do
        it 'sets #no_fingerprinting to true' do
            Arachni::Options.fingerprint?.should be_true
            Arachni::Options.no_fingerprinting.should be_false

            Arachni::Options.do_not_fingerprint
            Arachni::Options.fingerprint?.should be_false
            Arachni::Options.no_fingerprinting.should be_true
        end
    end

    describe '#fingerprint' do
        it 'sets #no_fingerprinting to false' do
            Arachni::Options.do_not_fingerprint
            Arachni::Options.fingerprint?.should be_false
            Arachni::Options.no_fingerprinting.should be_true

            Arachni::Options.fingerprint

            Arachni::Options.fingerprint?.should be_true
            Arachni::Options.no_fingerprinting.should be_false
        end
    end

    describe '#fingerprint?' do
        context 'by default' do
            it 'returns true' do
                Arachni::Options.fingerprint?.should be_true
            end
        end
        context 'when crawling is enabled' do
            it 'returns true' do
                Arachni::Options.do_not_fingerprint
                Arachni::Options.fingerprint?.should be_false
                Arachni::Options.fingerprint
                Arachni::Options.fingerprint?.should be_true
            end
        end
        context 'when crawling is disabled' do
            it 'returns false' do
                Arachni::Options.fingerprint?.should be_true
                Arachni::Options.do_not_fingerprint
                Arachni::Options.fingerprint?.should be_false
            end
        end
    end

    describe '#do_not_crawl' do
        it 'sets the link_count_limit to 0' do
            Arachni::Options.do_not_crawl
            Arachni::Options.link_count_limit.should == 0
        end
    end

    describe '#crawl' do
        it 'sets the link_count_limit to < 0' do
            Arachni::Options.crawl
            Arachni::Options.crawl?.should be_true
            !Arachni::Options.link_count_limit.should be_nil
        end
    end

    describe '#crawl?' do
        context 'by default' do
            it 'returns true' do
                Arachni::Options.crawl?.should be_true
            end
        end
        context 'when crawling is enabled' do
            it 'returns true' do
                Arachni::Options.do_not_crawl
                Arachni::Options.crawl?.should be_false
                Arachni::Options.crawl
                Arachni::Options.crawl?.should be_true
            end
        end
        context 'when crawling is disabled' do
            it 'returns false' do
                Arachni::Options.crawl?.should be_true
                Arachni::Options.do_not_crawl
                Arachni::Options.crawl?.should be_false
            end
        end
    end

    describe '#link_count_limit_reached?' do
        context 'when the link count limit has' do

            context 'not been set' do
                it 'returns false' do
                    Arachni::Options.link_count_limit_reached?( 44 ).should be_false
                end
            end

            context 'not been reached' do
                it 'returns false' do
                    Arachni::Options.link_count_limit = 5
                    Arachni::Options.link_count_limit_reached?( 2 ).should be_false
                end
            end

            context 'been reached' do
                it 'returns true' do
                    Arachni::Options.link_count_limit = 5
                    Arachni::Options.link_count_limit_reached?( 5 ).should be_true
                    Arachni::Options.link_count_limit_reached?( 6 ).should be_true
                end
            end
        end

    end

    describe '#audit' do
        it 'enables auditing of the given element types' do
            Arachni::Options.audit_links.should be_false
            Arachni::Options.audit_forms.should be_false
            Arachni::Options.audit_cookies.should be_false
            Arachni::Options.audit_headers.should be_false

            Arachni::Options.audit :links, :forms, :cookies, :headers

            Arachni::Options.audit_links.should be_true
            Arachni::Options.audit_forms.should be_true
            Arachni::Options.audit_cookies.should be_true
            Arachni::Options.audit_headers.should be_true
        end
    end

    describe '#audit=' do
        it 'enables auditing of the given element types' do
            Arachni::Options.audit_links.should be_false
            Arachni::Options.audit_forms.should be_false
            Arachni::Options.audit_cookies.should be_false
            Arachni::Options.audit_headers.should be_false

            Arachni::Options.audit = :links, :forms, :cookies, :headers

            Arachni::Options.audit_links.should be_true
            Arachni::Options.audit_forms.should be_true
            Arachni::Options.audit_cookies.should be_true
            Arachni::Options.audit_headers.should be_true
        end
    end

    describe '#dont_audit' do
        it 'enables auditing of the given element types' do
            Arachni::Options.audit :links, :forms, :cookies, :headers

            Arachni::Options.audit_links.should be_true
            Arachni::Options.audit_forms.should be_true
            Arachni::Options.audit_cookies.should be_true
            Arachni::Options.audit_headers.should be_true

            Arachni::Options.dont_audit :links, :forms, :cookies, :headers

            Arachni::Options.audit_links.should be_false
            Arachni::Options.audit_forms.should be_false
            Arachni::Options.audit_cookies.should be_false
            Arachni::Options.audit_headers.should be_false
        end
    end

    describe '#audit?' do
        it 'returns a boolean value if he given element is to be audited' do
            Arachni::Options.audit_links.should be_false
            Arachni::Options.audit?( :links ).should be_false
            Arachni::Options.audit?( :link ).should be_false
            Arachni::Options.audit?( 'links' ).should be_false
            Arachni::Options.audit?( 'link' ).should be_false

            Arachni::Options.audit_forms.should be_false
            Arachni::Options.audit?( :forms ).should be_false
            Arachni::Options.audit?( :form ).should be_false
            Arachni::Options.audit?( 'forms' ).should be_false
            Arachni::Options.audit?( 'form' ).should be_false

            Arachni::Options.audit_cookies.should be_false
            Arachni::Options.audit?( :cookies ).should be_false
            Arachni::Options.audit?( :cookie ).should be_false
            Arachni::Options.audit?( 'cookies' ).should be_false
            Arachni::Options.audit?( 'cookie' ).should be_false

            Arachni::Options.audit_headers.should be_false
            Arachni::Options.audit?( :headers ).should be_false
            Arachni::Options.audit?( :header ).should be_false
            Arachni::Options.audit?( 'headers' ).should be_false
            Arachni::Options.audit?( 'header' ).should be_false

            Arachni::Options.audit?( :header, :link, :form, :cookie ).should be_false
            Arachni::Options.audit?( [:header, :link, :form, :cookie] ).should be_false

            Arachni::Options.audit :links, :forms, :cookies, :headers

            Arachni::Options.audit_links.should be_true
            Arachni::Options.audit?( :links ).should be_true
            Arachni::Options.audit?( :link ).should be_true
            Arachni::Options.audit?( 'links' ).should be_true
            Arachni::Options.audit?( 'link' ).should be_true

            Arachni::Options.audit_forms.should be_true
            Arachni::Options.audit?( :forms ).should be_true
            Arachni::Options.audit?( :form ).should be_true
            Arachni::Options.audit?( 'forms' ).should be_true
            Arachni::Options.audit?( 'form' ).should be_true

            Arachni::Options.audit_cookies.should be_true
            Arachni::Options.audit?( :cookies ).should be_true
            Arachni::Options.audit?( :cookie ).should be_true
            Arachni::Options.audit?( 'cookies' ).should be_true
            Arachni::Options.audit?( 'cookie' ).should be_true

            Arachni::Options.audit_headers.should be_true
            Arachni::Options.audit?( :headers ).should be_true
            Arachni::Options.audit?( :header ).should be_true
            Arachni::Options.audit?( 'headers' ).should be_true
            Arachni::Options.audit?( 'header' ).should be_true

            Arachni::Options.audit?( :header, :link, :form, :cookie ).should be_true
            Arachni::Options.audit?( [:header, :link, :form, :cookie] ).should be_true
        end
    end


    describe '#url' do
        it 'normalizes its param and set it as the target URL' do
            @opts.url = 'http://test.com/my path'
            @opts.url.should == @utils.normalize_url( @opts.url )
        end

        context 'when a relative URL is passed' do
            it 'throws an exception' do
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
            it 'throws an exception' do
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
            it 'sets options by hash' do
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
            it 'sets options by hash' do
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
        it 'converts its param to an array of strings' do
            cookies = %w(my_cookie my_other_cookie)

            @opts.exclude_cookies = cookies.first
            @opts.exclude_cookies.should == [cookies.first]

            @opts.exclude_cookies = cookies
            @opts.exclude_cookies.should == cookies
        end
    end

    describe '#exclude_vectors=' do
        it 'converts its param to an array of strings' do
            vectors = %w(my_vector my_other_vector)

            @opts.exclude_vectors = vectors.first
            @opts.exclude_vectors.should == [vectors.first]

            @opts.exclude_vectors = vectors
            @opts.exclude_vectors.should == vectors
        end
    end

    describe '#mods=' do
        it 'converts its param to an array of strings' do
            mods = %w(my_mods my_other_mods)

            @opts.mods = mods.first
            @opts.mods.should == [mods.first]

            @opts.mods = mods
            @opts.mods.should == mods
        end

        it 'aliased to #modules=' do
            mods = %w(my_mods my_other_mods)

            @opts.mods = mods.first
            @opts.modules.should == [mods.first]

            @opts.modules = mods
            @opts.mods.should == mods
        end
    end

    describe '#restrict_paths=' do
        it 'converts its param to an array of strings' do
            restrict_paths = %w(my_restrict_paths my_other_restrict_paths)

            @opts.restrict_paths = restrict_paths.first
            @opts.restrict_paths.should == [restrict_paths.first]

            @opts.restrict_paths = restrict_paths
            @opts.restrict_paths.should == restrict_paths
        end
    end

    describe '#extend_paths=' do
        it 'converts its param to an array of strings' do
            extend_paths = %w(my_extend_paths my_other_extend_paths)

            @opts.extend_paths = extend_paths.first
            @opts.extend_paths.should == [extend_paths.first]

            @opts.extend_paths = extend_paths
            @opts.extend_paths.should == extend_paths
        end
    end

    describe '#include=' do
        it 'converts its param to an array of strings' do
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
        it 'converts its param to an array of strings' do
            exclude = %w(my_exclude my_other_exclude)

            @opts.exclude = /test/
            @opts.exclude.should == [/test/]

            @opts.exclude = exclude.first
            @opts.exclude.should == [Regexp.new( exclude.first )]

            @opts.exclude = exclude
            @opts.exclude.should == exclude.map { |p| Regexp.new( p ) }
        end
    end

    describe '#exclude_pages=' do
        it 'converts its param to an array of strings' do
            exclude_pages = %w(my_ignore my_other_ignore)

            @opts.exclude_pages = /test/
            @opts.exclude_pages.should == [/test/]

            @opts.exclude_pages = exclude_pages.first
            @opts.exclude_pages.should == [Regexp.new( exclude_pages.first )]

            @opts.exclude_pages = exclude_pages
            @opts.exclude_pages.should == exclude_pages.map { |p| Regexp.new( p ) }
        end
    end

    describe '#exclude_pages?' do
        context 'when the string matches one of the #ignore patterns' do
            it 'returns true' do
                @opts.exclude_pages = /test/
                @opts.exclude_page?( 'this is a test test test' ).should be_true
            end
        end
        context 'when the string does not match one of the #ignore patterns' do
            it 'returns false' do
                @opts.exclude_pages = /test/
                @opts.exclude_page?( 'this is a blah blah blah' ).should be_false
            end
        end
    end


    describe '#lsmod=' do
        it 'converts its param to an array of strings' do
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
        it 'converts its param to an array of strings' do
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
        it 'converts its param to an array of strings' do
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
        it 'converts its param to properly typed filters' do
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
        it 'tries to cast its param to a Hash' do
            @opts.datastore = [[ :k, 'val' ]]
            @opts.datastore.should == { k: 'val' }

            @opts.datastore = { key: 'value' }
            @opts.datastore.should == { key: 'value' }
        end
    end

    describe '#serialize' do
        it 'returns an one-line serialized version of self' do
            s = @opts.serialize
            s.is_a?( String ).should be_true
            s.include?( "\n" ).should be_false
        end
    end

    describe '#unserialize' do
        it 'unserializes the return value of #serialize' do
            s = @opts.serialize
            @opts.unserialize( s ).should == @opts
        end
    end

    describe '#save' do
        it 'dumps a serialized version of self to a file' do
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
        it 'loads a serialized version of self' do
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

        it 'supports a serialized Hash' do
            f = 'options'

            File.open( f, 'w' ) { |file| YAML.dump( @opts.to_hash, file ) }

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
        it 'converts self to a hash' do
            h = @opts.to_hash
            h.is_a?( Hash ).should be_true

            h.each { |k, v| @opts.instance_variable_get( "@#{k}".to_sym ).should == v }
        end
    end

    describe '#to_h' do
        it 'aliased to to_hash' do
            @opts.to_hash.should == @opts.to_h
        end
    end

    describe '#==' do
        context 'when both objects are equal' do
            it 'returns true' do
                @opts.should == @opts
            end
        end
        context 'when objects are not equal' do
            it 'returns true' do
                @opts.should_not == @opts.load( @opts.save( 'test_opts' ) )
                File.delete( 'test_opts' )
            end
        end
    end

    describe '#merge!' do
        context 'when the param is a' do
            context Arachni::Options do
                it 'merges self with the passed object' do
                    opts = @opts.load( @opts.save( 'test_opts' ) )
                    File.delete( 'test_opts' )

                    opts.nickname = 'billybob'
                    @opts.nickname.should be_nil
                    @opts.merge!( opts )
                    @opts.nickname.should == 'billybob'
                end
            end
            context Hash do
                it 'merges self with the passed object' do
                    @opts.depth_limit = 20
                    @opts.depth_limit.should == 20

                    @opts.merge!( { depth_limit: 10 } )
                    @opts.depth_limit.should == 10
                end
            end
        end

        it 'skips nils and empty Arrays or Hashes' do
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
