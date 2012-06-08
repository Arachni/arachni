require_relative '../spec_helper'

describe Arachni::Spider do
    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.url = server_url_for :spider
        @url = @opts.url.to_s
    end

    before( :each ) do
        reset_options
        @opts.url = @url
        Arachni::HTTP.instance.reset
    end

    it 'should avoid infinite loops' do
        @opts.url = @url + 'loop'
        sitemap = Arachni::Spider.new.run

        expected = [ @opts.url, @opts.url + '_back' ]
        (sitemap & expected).sort.should == expected.sort
    end

    it 'should preserve cookies' do
        @opts.url = @url + 'with_cookies'
        Arachni::Spider.new.run.
            include?( @url + 'with_cookies3' ).should be_true
    end

    describe '#new' do
        it 'should be initialized using the passed options' do
            Arachni::Spider.new( @opts ).url.should == @url
        end

        context 'when called without params' do
            it 'should default to Arachni::Options.instance' do
                Arachni::Spider.new.url.should == @url
            end
        end

        context 'when the <extend_paths> option has been set' do
            it 'should add those paths to be followed' do
                @opts.extend_paths = %w(some_path)
                s = Arachni::Spider.new
                s.paths.sort.should == ([@url] | [@url + @opts.extend_paths.first]).sort
            end
        end
    end

    describe '#opts' do
        it 'should return the init options' do
            Arachni::Spider.new.opts.should == @opts
        end
    end

    describe '#redirects' do
        it 'should hold an array of requested URLs that caused a redirect' do
            @opts.url = @url + 'redirect'
            s = Arachni::Spider.new
            s.run
            s.redirects.should == [ s.url ]
        end
    end

    describe '#url' do
        it 'should return the seed URL' do
            Arachni::Spider.new.url.should == @url
        end
    end

    describe '#sitemap' do
        context 'when just initialized' do
            it 'should be empty' do
                Arachni::Spider.new.sitemap.should be_empty
            end
        end

        context 'after a crawl' do
            it 'should return a list of crawled URLs' do
                s = Arachni::Spider.new
                s.run
                s.sitemap.include?( @url ).should be_true
            end
        end
    end

    describe '#fancy_sitemap' do
        context 'when just initialized' do
            it 'should be empty' do
                spider = Arachni::Spider.new
                spider.fancy_sitemap.should be_empty
            end
        end

        context 'after a crawl' do
            it 'should return a hash of crawled URLs with their HTTP response codes' do
                spider = Arachni::Spider.new
                spider.run
                spider.fancy_sitemap.include?( @url ).should be_true
                spider.fancy_sitemap[@url].should == 200
                spider.fancy_sitemap[@url + 'this_does_not_exist' ].should == 404
            end
        end
    end

    describe '#run' do
        context 'when the link-count-limit option has been set' do
            it 'should follow only a <link-count-limit> amount of paths' do
                @opts.link_count_limit = 1
                spider = Arachni::Spider.new
                spider.run.should == spider.sitemap
                spider.sitemap.should == [@url]

                @opts.link_count_limit = 2
                spider = Arachni::Spider.new
                spider.run.should == spider.sitemap
                spider.sitemap.size.should == 2
            end
        end
        context 'when redundant rules have been set' do
            it 'should follow the matching paths the specified amounts of time' do
                @opts.url = @url + '/redundant'

                @opts.redundant = { 'redundant' => 2 }
                spider = Arachni::Spider.new
                spider.run.select { |url| url.include?( 'redundant') }.size.should == 2

                @opts.redundant = { 'redundant' => 3 }
                spider = Arachni::Spider.new
                spider.run.select { |url| url.include?( 'redundant') }.size.should == 3
            end
        end
        context 'when called without parameters' do
            it 'should perform a crawl and return the sitemap' do
                spider = Arachni::Spider.new
                spider.run.should == spider.sitemap
                spider.sitemap.should be_any
            end
        end
        context 'when called with a block only' do
            it 'should pass the block each page as visited' do
                spider = Arachni::Spider.new
                pages = []
                spider.run { |page| pages << page }
                pages.size.should == spider.sitemap.size
                pages.first.is_a?( Arachni::Parser::Page ).should be_true
            end
        end
        context 'when called with options and a block' do
            describe :pass_pages_to_block do
                describe true do
                    it 'should pass the block each page as visited' do
                        spider = Arachni::Spider.new
                        pages = []
                        spider.run( true ) { |page| pages << page }
                        pages.size.should == spider.sitemap.size
                        pages.first.is_a?( Arachni::Parser::Page ).should be_true
                    end
                end
                describe false do
                    it 'should pass the block each HTTP response as received' do
                        spider = Arachni::Spider.new
                        responses = []
                        spider.run( false ) { |res| responses << res }
                        responses.size.should == spider.sitemap.size
                        responses.first.is_a?( Typhoeus::Response ).should be_true
                    end
                end
            end
        end
    end

    describe '#on_each_page' do
        context 'when no modifier has been previously called' do
            it 'should be passed each page as visited' do
                pages  = []
                pages2 = []

                s = Arachni::Spider.new

                s.on_each_page { |page| pages << page }.should == s
                s.on_each_page { |page| pages2 << page }.should == s

                s.run

                pages.should == pages2

                pages.size.should == s.sitemap.size
                pages.first.is_a?( Arachni::Parser::Page ).should be_true
            end
        end
        context 'when #pass_responses has been called' do
            it 'should be passed each HTTP response as received' do
                spider = Arachni::Spider.new

                responses  = []
                responses2 = []

                spider.pass_responses

                spider.on_each_page { |res| responses << res }.should == spider
                spider.on_each_page { |res| responses2 << res }.should == spider

                spider.run

                responses.should == responses2

                responses.size.should == spider.sitemap.size
                responses.first.is_a?( Typhoeus::Response ).should be_true
            end
        end
    end

    describe '#pass_pages?' do
        context 'when no modifier has been previously called' do
            it 'should return true' do
                Arachni::Spider.new.pass_pages?.should be_true
            end
        end
        context 'when #pass_responses has been called' do
            it 'should return false' do
                s = Arachni::Spider.new
                s.pass_responses
                s.pass_pages?.should be_false
            end
        end
        context 'when #pass_pages has been called' do
            it 'should return true' do
                s = Arachni::Spider.new
                s.pass_responses
                s.pass_pages?.should be_false
                s.pass_pages
                s.pass_pages?.should be_true
            end
        end
    end

    describe '#on_complete' do
        it 'should be called once the crawl it done' do
            s = Arachni::Spider.new
            called = false
            called2 = false
            s.on_complete { called = true }.should == s
            s.on_complete { called2 = true }.should == s
            s.run
            called.should == called2
            called.should be_true
        end
    end

    describe '#push' do
        it 'should push paths for the crawler to follow' do
            s = Arachni::Spider.new
            path = @url + 'a_pushed_path'
            s.push( path )
            s.paths.include?( path ).should be_true
            s.run
            s.paths.include?( path ).should be_false
            s.sitemap.include?( path ).should be_true

            s = Arachni::Spider.new
            paths = [@url + 'a_pushed_path', @url + 'another_pushed_path']
            s.push( paths )
            (s.paths & paths).sort.should == paths.sort
            s.run
            (s.paths & paths).should be_empty
            (s.sitemap & paths).sort.should == paths.sort
        end

        it 'should normalize and follow the pushed paths' do
            s = Arachni::Spider.new
            p = 'some-path blah! %&$'

            wp = 'another weird path %"&*[$)'
            nwp = Arachni::Module::Utilities.to_absolute( wp )
            np = Arachni::Module::Utilities.to_absolute( p )

            s.push( p )
            s.run
            s.fancy_sitemap[np].should == 200
            s.fancy_sitemap[nwp].should == 200
        end

        context 'when called after the crawl has finished' do
            it 'should wake the crawler up after pushing the new paths' do
                s = Arachni::Spider.new
                s.run
                s.done?.should be_true
                s.push( '/a_pushed_path' )
                s.done?.should be_false
            end
        end
    end

    describe '#done?' do
        context 'when not running' do
            it 'should return false' do
                s = Arachni::Spider.new
                s.done?.should be_false
            end
        end
        context 'when running' do
            it 'should return false' do
                s = Arachni::Spider.new
                Thread.new{ s.run }
                s.done?.should be_false
            end
        end
        context 'when it has finished' do
            it 'should return true' do
                s = Arachni::Spider.new
                s.run
                s.done?.should be_true
            end
        end
    end

    describe '#pause' do
        it 'should pause a running crawl' do
            s = Arachni::Spider.new
            Thread.new{ s.run }
            s.pause
            sleep 1
            s.sitemap.should be_empty
        end
    end

    describe '#paused?' do
        context 'when the crawl is not paused' do
            it 'should return false' do
                s = Arachni::Spider.new
                s.paused?.should be_false
            end
        end
        context 'when the crawl is paused' do
            it 'should return true' do
                s = Arachni::Spider.new
                s.pause
                s.paused?.should be_true
            end
        end
    end

    describe '#resume' do
        it 'should resume a paused crawl' do
            s = Arachni::Spider.new
            Thread.new{ s.run }
            s.pause
            sleep 1
            s.sitemap.should be_empty
            s.done?.should be_false
            s.resume
            sleep 1
            s.sitemap.should be_any
            s.done?.should be_true
        end
    end

end
