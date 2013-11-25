require 'spec_helper'

describe Arachni::Spider do
    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.url = web_server_url_for :spider
        @url = @opts.url.to_s
    end

    before( :each ) do
        reset_options
        @opts.url = @url
        Arachni::HTTP::Client.reset
    end

    it 'supports HTTPS' do
        @opts.url = web_server_url_for( :spider_https ).gsub( 'http', 'https' )
        spider = Arachni::Spider.new

        spider.run.size.should == 3
        spider.redirects.size.should == 2
    end

    it 'avoids infinite loops' do
        @opts.url = @url + 'loop'
        sitemap = Arachni::Spider.new.run

        expected = [ @opts.url, @opts.url + '_back' ]
        (sitemap & expected).sort.should == expected.sort
    end

    it 'preserves cookies' do
        @opts.url = @url + 'with_cookies'
        Arachni::Spider.new.run.
            include?( @url + 'with_cookies3' ).should be_true
    end

    it 'ignores redirections to foreign domains' do
        @opts.url = @url + 'foreign_domain'
        Arachni::Spider.new.run.should == [ @opts.url ]
    end

    context 'when unable to get a response for the given URL' do
        context 'due to a network error' do
            it 'returns an empty sitemap and have failures' do
                @opts.url = 'http://blahaha'

                s = Arachni::Spider.new( @opts )

                s.url.should == @opts.url
                s.run.should be_empty
                s.failures.should be_any
            end
        end

        context 'due to a server error' do
            it 'returns an empty sitemap and have failures' do
                @opts.url = @url + '/fail'

                s = Arachni::Spider.new( @opts )

                s.url.should == @opts.url
                s.run.should be_empty
                s.failures.should be_any
            end
        end

        it "retries #{Arachni::Spider::MAX_TRIES} times" do
            @opts.url = @url + '/fail_4_times'

            s = Arachni::Spider.new( @opts )

            s.url.should == @opts.url
            s.run.should be_any
        end
    end

    describe '#failures' do
        context 'when there are no failed requests' do
            it 'returns an empty array' do
                s = Arachni::Spider.new( @opts )
                s.run.should be_any
                s.failures.should be_empty
            end
        end
        context 'when there are failed requests' do
            it 'returns an array containing the failed URLs' do
                @opts.url = 'http://blahaha/'

                s = Arachni::Spider.new( @opts )

                s.url.should == @opts.url

                s.run.should be_empty
                s.failures.should be_any
                s.failures.should include( @opts.url )
            end
        end
    end


    describe '.new' do
        it 'initializes it using the passed options' do
            Arachni::Spider.new( @opts ).url.should == @url
        end

        context 'when called without params' do
            it 'defaults to Arachni::Options.instance' do
                Arachni::Spider.new.url.should == @url
            end
        end

        context 'when the Options#extend_paths has been set' do
            it 'adds those paths to be followed' do
                @opts.extend_paths = %w(some_path)
                s = Arachni::Spider.new
                s.paths.sort.should == ([@url] | [@url + @opts.extend_paths.first]).sort
            end
        end
    end

    describe '#opts' do
        it 'returns the init options' do
            Arachni::Spider.new.opts.should == @opts
        end
    end

    describe '#redirects' do
        it 'holds an array of requested URLs that caused a redirect' do
            @opts.url = @url + 'redirect'
            s = Arachni::Spider.new
            s.run
            s.redirects.should == [ s.url ]
        end
    end

    describe '#url' do
        it 'returns the seed URL' do
            Arachni::Spider.new.url.should == @url
        end
    end

    describe '#sitemap' do
        context 'when just initialized' do
            it 'is empty' do
                Arachni::Spider.new.sitemap.should be_empty
            end
        end

        context 'after a crawl' do
            it 'returns a list of crawled URLs' do
                s = Arachni::Spider.new
                s.run
                s.sitemap.include?( @url ).should be_true
            end
        end
    end

    describe '#fancy_sitemap' do
        context 'when just initialized' do
            it 'is empty' do
                spider = Arachni::Spider.new
                spider.fancy_sitemap.should be_empty
            end
        end

        context 'after a crawl' do
            it 'returns a hash of crawled URLs with their HTTP response codes' do
                spider = Arachni::Spider.new
                spider.run
                spider.fancy_sitemap.include?( @url ).should be_true
                spider.fancy_sitemap[@url].should == 200
                spider.fancy_sitemap[@url + 'this_does_not_exist' ].should == 404
            end
        end
    end

    describe '#run' do
        it 'performs the crawl' do
            @opts.url = @url + '/lots_of_paths'

            spider = Arachni::Spider.new
            spider.run.size.should == 10051
        end

        it 'ignores path parameters' do
            @opts.url = @url + '/path_params'

            spider = Arachni::Spider.new
            spider.run.select { |url| url.include?( '/something' ) }.size.should == 1
        end

        context 'Options.exclude_pages' do
            it 'skips pages which match the configured patterns (but not the seed URL)' do
                @opts.exclude_pages = /skip-me/i
                @opts.url = "#{@url}skip"

                Arachni::Spider.new.run.should == [@opts.url, "#{@url}follow-me"]
            end
        end

        context 'Options.exclude' do
            it 'skips paths which match the configured patterns (but not the seed URL)' do
                @opts.exclude = /skip-me/i
                @opts.url = "#{@url}skip"

                Arachni::Spider.new.run.should == [@opts.url, "#{@url}follow-me"]
            end
        end

        context 'Options.include' do
            it 'skips paths which do not match the configured patterns (but not the seed URL)' do
                @opts.include = /include-me/i
                @opts.url = "#{@url}include"

                Arachni::Spider.new.run.sort.should ==
                    [@opts.url, "#{@url}include-me/1", "#{@url}include-me/2"].sort
            end
        end

        context 'Options.do_not_crawl' do
            it 'does not crawl the site' do
                @opts.do_not_crawl
                Arachni::Spider.new.run.should be_nil
            end

            context 'when crawling is then enabled using Options.crawl' do
                it 'performs a crawl' do
                    @opts.crawl
                    Arachni::Spider.new.run.should be_any
                end
            end
        end
        context 'Options.auto_redundant' do
            describe 5 do
                it 'only crawls 5 URLs with identical query parameter names' do
                    @opts.auto_redundant = 5
                    @opts.url += 'auto-redundant'
                    Arachni::Spider.new.run.size.should == 11
                end
            end
        end
        context 'when the link-count-limit option has been set' do
            context 'and the limit has been reached' do
                it 'immediately returns' do
                    @opts.link_count_limit = 1
                    spider = Arachni::Spider.new
                    spider.run.should == spider.sitemap
                    spider.sitemap.should == [@url]

                    spider.run.should be_false
                end
            end

            it 'follows only a <link-count-limit> amount of paths' do
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
            it 'follows the matching paths the specified amounts of time' do
                @opts.url = @url + '/redundant'

                @opts.redundant = { 'redundant' => 2 }
                spider = Arachni::Spider.new
                spider.run.select { |url| url.include?( 'redundant' ) }.size.should == 2

                @opts.redundant = { 'redundant' => 3 }
                spider = Arachni::Spider.new
                spider.run.select { |url| url.include?( 'redundant' ) }.size.should == 3
            end
        end
        context 'when called without parameters' do
            it 'performs a crawl and return the sitemap' do
                spider = Arachni::Spider.new
                spider.run.should == spider.sitemap
                spider.sitemap.should be_any
            end
        end
        context 'when called with a block only' do
            it 'passes the block each page as visited' do
                spider = Arachni::Spider.new
                pages = []
                spider.run { |page| pages << page }
                pages.size.should == spider.sitemap.size
                pages.first.is_a?( Arachni::Page ).should be_true
            end
        end
        context 'when a redirect that is outside the scope is encountered' do
            it 'is ignored' do
                @opts.url = @url + '/skip_redirect'

                spider = Arachni::Spider.new
                spider.run.should be_empty
                spider.redirects.size.should == 1
            end
        end
        it 'follows relative redirect locations' do
            @opts.url = @url + '/relative_redirect'
            @opts.redirect_limit = -1

            spider = Arachni::Spider.new
            spider.run.select { |url| url.include?( 'stacked_redirect4' ) }.should be_any
        end
        it 'follows stacked redirects' do
            @opts.url = @url + '/stacked_redirect'
            @opts.redirect_limit = -1

            spider = Arachni::Spider.new
            spider.run.select { |url| url.include?( 'stacked_redirect4' ) }.should be_any
        end
        it 'ignores stacked redirects that exceed the limit' do
            @opts.url = @url + '/stacked_redirect'
            @opts.redirect_limit = 3

            spider = Arachni::Spider.new
            spider.run.size.should == 3
        end

        context 'when called with a block' do
            it 'passes the block each page as visited' do
                spider = Arachni::Spider.new
                pages = []
                spider.run { |page| pages << page }
                pages.size.should == spider.sitemap.size
                pages.first.is_a?( Arachni::Page ).should be_true
            end
        end
    end

    describe '#on_each_page' do
        it 'is passed each page as visited' do
            pages  = []
            pages2 = []

            s = Arachni::Spider.new

            s.on_each_page { |page| pages << page }.should == s
            s.on_each_page { |page| pages2 << page }.should == s

            s.run

            pages.should == pages2

            pages.size.should == s.sitemap.size
            pages.first.is_a?( Arachni::Page ).should be_true
        end
    end

    describe '#on_complete' do
        it 'is called once the crawl it done' do
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
        it 'pushes paths for the crawler to follow' do
            s = Arachni::Spider.new
            path = @url + 'a_pushed_path'
            s.push( path )
            s.paths.include?( path ).should be_true
            s.run
            s.paths.include?( path ).should be_false
            s.sitemap.include?( path ).should be_true

            s = Arachni::Spider.new
            paths = [@url + 'a_pushed_path', @url + 'another_pushed_path']
            s.push( paths ).should be_true
            (s.paths & paths).sort.should == paths.sort
            s.run
            (s.paths & paths).should be_empty
            (s.sitemap & paths).sort.should == paths.sort
        end

        it 'normalizes and follow the pushed paths' do
            s = Arachni::Spider.new
            p = 'some-path blah! %&$'

            wp = 'another weird path %"&*[$)'
            nwp = Arachni::Utilities.to_absolute( wp )
            np = Arachni::Utilities.to_absolute( p )

            s.push( p ).should be_true
            s.run
            s.fancy_sitemap[np].should == 200
            s.fancy_sitemap[nwp].should == 200
        end

        context 'when the link-count-limit option has been set' do
            context 'and the limit has been reached' do
                it 'immediately returns' do
                    @opts.link_count_limit = 1
                    spider = Arachni::Spider.new
                    spider.run.should == spider.sitemap
                    spider.sitemap.should == [@url]

                    spider.push( Arachni::Utilities.to_absolute( 'test' ) ).should be_false
                end
            end
        end
    end

    describe '#done?' do
        context 'when not running' do
            it 'returns false' do
                s = Arachni::Spider.new
                s.done?.should be_false
            end
        end
        context 'when running' do
            it 'returns false' do
                s = Arachni::Spider.new
                Thread.new{ s.run }
                s.done?.should be_false
            end
        end
        context 'when it has finished' do
            it 'returns true' do
                s = Arachni::Spider.new
                s.run
                s.done?.should be_true
            end
        end
    end

    describe '#running?' do
        context 'when not running' do
            it 'returns false' do
                s = Arachni::Spider.new
                s.running?.should be_false
            end
        end
        context 'when running' do
            it 'returns false' do
                @opts.url = web_server_url_for( :auditor ) + '/sleep'
                s = Arachni::Spider.new
                Thread.new{ s.run }
                sleep 1
                s.running?.should be_true
            end
        end
        context 'when it has finished' do
            it 'returns true' do
                s = Arachni::Spider.new
                s.run
                s.running?.should be_false
            end
        end
    end

    describe '#pause' do
        it 'pauses a running crawl' do
            s = Arachni::Spider.new
            Thread.new{ s.run }
            s.pause
            sleep 1
            s.sitemap.should be_empty
        end
    end

    describe '#paused?' do
        context 'when the crawl is not paused' do
            it 'returns false' do
                s = Arachni::Spider.new
                s.paused?.should be_false
            end
        end
        context 'when the crawl is paused' do
            it 'returns true' do
                s = Arachni::Spider.new
                s.pause
                s.paused?.should be_true
            end
        end
    end

    describe '#resume' do
        it 'resumes a paused crawl' do
            @opts.url = @url + 'sleep'
            s = Arachni::Spider.new
            s.pause
            Thread.new{ s.run }
            sleep 1
            s.sitemap.should be_empty
            s.done?.should be_false
            s.resume
            sleep 0.1 while !s.done?
            s.sitemap.should be_any
            s.done?.should be_true
        end
    end

end
