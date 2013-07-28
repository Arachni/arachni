require 'spec_helper'

describe Arachni::Browser do

    before( :all ) do
        @url = Arachni::Utilities.normalize_url( web_server_url_for( :browser ) )
        @browser = described_class.new
    end

    after( :each ) do
        @browser.flush_pages
        @browser.cache.clear
        @browser.preloads.clear
        clear_hit_count
    end

    let( :ua ) { Arachni::Options.user_agent }

    def hit_count
        Typhoeus::Request.get( "#{@url}/hit-count" ).body.to_i
    end

    def clear_hit_count
        Typhoeus::Request.get( "#{@url}/clear-hit-count" )
    end

    describe '#source' do
        it 'returns the evaluated HTML source' do
            @browser.load @url

            ua = Arachni::Options.user_agent
            ua.should_not be_empty

            @browser.source.should include( ua )
        end
    end

    describe '#watir' do
        it 'provides access to the Watir::Browser API' do
            @browser.watir.should be_kind_of Watir::Browser
        end
    end

    describe '#selenium' do
        it 'provides access to the Selenium::WebDriver::Driver API' do
            @browser.selenium.should be_kind_of Selenium::WebDriver::Driver
        end
    end

    describe '#load' do
        context 'when given a' do
            describe String do
                it 'treats it as a URL' do
                    hit_count.should == 0

                    @browser.load @url
                    @browser.source.should include( ua )
                    @browser.preloads.should_not include( @url )

                    hit_count.should == 1
                end
            end

            describe Arachni::HTTP::Response do
                it 'loads it' do
                    hit_count.should == 0

                    @browser.load Arachni::HTTP::Client.get( @url, mode: :sync )
                    @browser.source.should include( ua )
                    @browser.preloads.should_not include( @url )

                    hit_count.should == 1
                end
            end

            describe Arachni::Page do
                it 'loads it' do
                    hit_count.should == 0

                    @browser.load Arachni::HTTP::Client.get( @url, mode: :sync ).to_page
                    @browser.source.should include( ua )
                    @browser.preloads.should_not include( @url )

                    hit_count.should == 1
                end
            end
        end
    end

    describe '#preload' do
        it 'removes entries after they are used' do
            @browser.preload Arachni::HTTP::Client.get( @url, mode: :sync )
            clear_hit_count

            hit_count.should == 0

            @browser.load @url
            @browser.source.should include( ua )
            @browser.preloads.should_not include( @url )

            hit_count.should == 0

            2.times do
                @browser.load @url
                @browser.source.should include( ua )
            end

            @browser.preloads.should_not include( @url )

            hit_count.should == 2
        end

        context 'when given a' do
            describe Arachni::HTTP::Response do
                it 'preloads it' do
                    @browser.preload Arachni::HTTP::Client.get( @url, mode: :sync )
                    clear_hit_count

                    hit_count.should == 0

                    @browser.load @url
                    @browser.source.should include( ua )
                    @browser.preloads.should_not include( @url )

                    hit_count.should == 0
                end
            end

            describe Arachni::Page do
                it 'preloads it' do
                    @browser.preload Arachni::Page.from_url( @url )
                    clear_hit_count

                    hit_count.should == 0

                    @browser.load @url
                    @browser.source.should include( ua )
                    @browser.preloads.should_not include( @url )

                    hit_count.should == 0
                end
            end
        end
    end

    describe '#cache' do
        it 'keeps entries after they are used' do
            @browser.cache Arachni::HTTP::Client.get( @url, mode: :sync )
            clear_hit_count

            hit_count.should == 0

            @browser.load @url
            @browser.source.should include( ua )
            @browser.cache.should include( @url )

            hit_count.should == 0

            2.times do
                @browser.load @url
                @browser.source.should include( ua )
            end

            @browser.cache.should include( @url )

            hit_count.should == 0
        end

        context 'when given a' do
            describe Arachni::HTTP::Response do
                it 'caches it' do
                    @browser.cache Arachni::HTTP::Client.get( @url, mode: :sync )
                    clear_hit_count

                    hit_count.should == 0

                    @browser.load @url
                    @browser.source.should include( ua )
                    @browser.cache.should include( @url )

                    hit_count.should == 0
                end
            end

            describe Arachni::Page do
                it 'caches it' do
                    @browser.cache Arachni::Page.from_url( @url )
                    clear_hit_count

                    hit_count.should == 0

                    @browser.load @url
                    @browser.source.should include( ua )
                    @browser.cache.should include( @url )

                    hit_count.should == 0
                end
            end
        end
    end

    describe '#start_capture' do
        it 'starts capturing requests and parses them into pages' do
            @browser.start_capture
            @browser.load @url + '/with-ajax'

            pages = @browser.flush_pages
            pages.size.should == 1

            page = pages.first

            page.links.find { |link| link.inputs.include? 'ajax-token' }.should be_true
        end

        context 'when a GET request is performed' do
            it 'is added as an Arachni::Link to the page' do
                @browser.start_capture
                @browser.load @url + '/with-ajax'

                pages = @browser.flush_pages
                pages.size.should == 1

                page = pages.first

                link = page.links.find { |link| link.inputs.include? 'ajax-token' }

                link.url.should == @url + 'with-ajax'
                link.action.should == @url + 'get-ajax?ajax-token=my-token'
                link.inputs.should == { 'ajax-token' => 'my-token' }
                link.method.should == :get
            end
        end

        context 'when a POST request is performed' do
            it 'is added as an Arachni::Form to the page' do
                @browser.start_capture
                @browser.load @url + '/with-ajax'

                pages = @browser.flush_pages
                pages.size.should == 1

                page = pages.first

                form = page.forms.find { |form| form.inputs.include? 'post-name' }

                form.url.should == @url + 'with-ajax'
                form.action.should == @url + 'post-ajax'
                form.inputs.should == { 'post-name' => 'post-value' }
                form.method.should == :post
            end
        end
    end

    describe '#flush_pages' do
        it 'flushes the captured pages' do
            @browser.start_capture
            @browser.load @url + '/with-ajax'

            pages = @browser.flush_pages
            pages.size.should == 1
            @browser.flush_pages.should be_empty
        end
    end

    describe '#stop_capture' do
        it 'stops the page capture' do
            @browser.start_capture
            @browser.load @url + '/with-ajax'
            @browser.load @url + '/with-image'
            @browser.flush_pages.size.should == 2

            @browser.start_capture
            @browser.load @url + '/with-ajax'
            @browser.stop_capture
            @browser.load @url + '/with-image'
            @browser.flush_pages.size.should == 1
        end
    end

    describe 'capture?' do
        it 'returns false' do
            @browser.start_capture
            @browser.stop_capture
            @browser.capture?.should be_false
        end

        context 'when capturing pages' do
            it 'returns true' do
                @browser.start_capture
                @browser.capture?.should be_true
            end
        end
        context 'when not capturing pages' do
            it 'returns false' do
                @browser.start_capture
                @browser.stop_capture
                @browser.capture?.should be_false
            end
        end
    end

    describe '#cookies' do
        it 'returns the browser cookies' do
            @browser.cookies.size.should == 1
            cookie = @browser.cookies.first

            cookie.should be_kind_of Arachni::Cookie
            cookie.name.should == 'stuff'
            cookie.value.should == 'true'
        end
    end

end
