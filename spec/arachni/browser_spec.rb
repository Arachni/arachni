require 'spec_helper'

describe Arachni::Browser do

    before( :all ) do
        @url = Arachni::Utilities.normalize_url( web_server_url_for( :browser ) )
    end

    before( :each ) do
        clear_hit_count
        @browser = described_class.new
    end

    after( :each ) do
        Arachni::Options.reset
        Arachni::Framework.reset
        @browser.close
        clear_hit_count
    end

    let( :ua ) { Arachni::Options.user_agent }

    def hit_count
        Typhoeus::Request.get( "#{@url}/hit-count" ).body.to_i
    end

    def clear_hit_count
        Typhoeus::Request.get( "#{@url}/clear-hit-count" )
    end

    def pages_should_have_form_with_input( pages, input_name )
        pages.find do |page|
            page.forms.find { |form| form.inputs.include? input_name }
        end.should be_true
    end

    it 'supports HTTPS' do
        url = web_server_url_for( :browser_https ).gsub( 'http', 'https' )

        @browser.start_capture
        pages = @browser.load( url ).flush_pages

        pages.size.should == 2
        pages_should_have_form_with_input( pages, 'ajax-token' )
        pages_should_have_form_with_input( pages, 'by-ajax' )
    end

    describe '#explore_deep_and_flush' do
        it 'handles deep DOM/page transitions' do
            pages = @browser.load( @url + '/deep-dom' ).explore_deep_and_flush

            pages_should_have_form_with_input pages, 'by-ajax'

            pages.map(&:transitions).should == [
                [
                    { :page => :load },
                    { "#{@url}deep-dom" => :request },
                    { "#{@url}level2" => :request }
                ],
                [
                    { :page => :load },
                    { "#{@url}deep-dom" => :request },
                    { "#{@url}level2" => :request },
                    { "<a onmouseover=\"writeButton();\" href=\"javascript:level3();\">" => :onclick },
                    { "#{@url}level4" => :request }
                ],
                [
                    { :page => :load },
                    { "#{@url}deep-dom" => :request },
                    { "#{@url}level2" => :request },
                    { "<a onmouseover=\"writeButton();\" href=\"javascript:level3();\">" => :onmouseover }
                ],
                [
                    { :page => :load },
                    { "#{@url}deep-dom" => :request },
                    { "#{@url}level2" => :request },
                    { "<a onmouseover=\"writeButton();\" href=\"javascript:level3();\">" => :onclick },
                    { "#{@url}level4" => :request },
                    { "<div onclick=\"level6();\" id=\"level5\">" => :onclick },
                    { "#{@url}level6" => :request }
                ],
                [
                    { :page => :load },
                    { "#{@url}deep-dom" => :request },
                    { "#{@url}level2" => :request },
                    { "<a onmouseover=\"writeButton();\" href=\"javascript:level3();\">" => :onmouseover },
                    { "<button onclick=\"writeUserAgent();\">" => :onclick }
                ]
            ]
        end
    end

    describe '#to_page' do
        it 'converts the working window to an Arachni::Page' do
            ua = Arachni::Options.user_agent

            @browser.load( @url )
            page = @browser.to_page

            page.should be_kind_of Arachni::Page

            ua.should_not be_empty
            page.body.should_not include( ua )
            page.dom_body.should include( ua )
        end

        it 'assigns the proper page transitions' do
            @browser.load( @url )
            page = @browser.to_page

            page.transitions.should == [
                { page: :load },
                { @url => :request }
            ]
        end
    end

    describe 'explore' do
        it 'triggers all events on all elements and follows all javascript links' do
            @browser.load( @url + '/explore' ).start_capture.explore

            pages_should_have_form_with_input @browser.page_snapshots, 'by-ajax'
            pages_should_have_form_with_input @browser.page_snapshots, 'from-post-ajax'
            pages_should_have_form_with_input @browser.captured_pages, 'ajax-token'
            pages_should_have_form_with_input @browser.captured_pages, 'href-post-name'
        end

        it 'assigns the proper page transitions' do
            pages = @browser.load( @url + '/explore' ).explore.page_snapshots

            transitions = pages.map(&:transitions)

            # The last one needs special treatment because of the unpredictable
            # order of AJAX requests.
            transition_with_lots_of_ajax = transitions.pop

            transitions.should == [
                [
                    { :page => :load },
                    { "#{@url}explore" => :request }
                ],
                [
                    { :page => :load },
                    { "#{@url}explore" => :request },
                    { "<div id=\"my-div\" onclick=\"addForm();\">" => :onclick },
                    { "#{@url}get-ajax?ajax-token=my-token" => :request }
                ]
            ]

            # We don't care about the order of AJAX requests.
            transition_with_lots_of_ajax.should =~ [
                { :page => :load },
                { "#{@url}explore" => :request },
                { "<a href=\"javascript:inHref();\">" => :click },
                { "#{@url}href-ajax" => :request },
                { "#{@url}post-ajax" => :request },
                { "#{@url}href-ajax" => :request }
            ]
        end

        it 'returns self' do
            @browser.load( @url + '/explore' ).explore.should == @browser
        end
    end

    describe '#trigger_events' do
        it 'waits for AJAX requests to complete' do
            @browser.load( @url + '/trigger_events-wait-for-ajax' ).start_capture.trigger_events

            pages_should_have_form_with_input @browser.captured_pages, 'ajax-token'
            pages_should_have_form_with_input @browser.page_snapshots, 'by-ajax'
        end

        it 'triggers all events on all elements' do
            @browser.load( @url + '/trigger_events' ).start_capture.trigger_events

            pages_should_have_form_with_input @browser.page_snapshots, 'by-ajax'
            pages_should_have_form_with_input @browser.captured_pages, 'ajax-token'
        end

        it 'assigns the proper page transitions' do
            pages = @browser.load( @url + '/trigger_events' ).trigger_events.page_snapshots
            pages.map(&:transitions).should == [
                [
                    { :page => :load },
                    { "#{@url}trigger_events" => :request },
                ],
                [
                    { :page => :load },
                    { "#{@url}trigger_events" => :request },
                    { "<div id=\"my-div\" onclick=\"addForm();\">" => :onclick },
                    { "#{@url}get-ajax?ajax-token=my-token" => :request }
                ]
            ]
        end

        it 'returns self' do
            @browser.load( @url + '/trigger_events' ).trigger_events.should == @browser
        end
    end

    describe '#visit_links' do
        it 'waits for AJAX requests to complete' do
            @browser.load( @url + '/visit_links-sleep' ).start_capture.visit_links

            pages_should_have_form_with_input @browser.captured_pages, 'href-post-name-sleep'
        end

        it 'visits all javascript links' do
            @browser.load( @url + '/visit_links' ).start_capture.visit_links

            pages_should_have_form_with_input @browser.captured_pages, 'href-post-name'
            pages_should_have_form_with_input @browser.page_snapshots, 'from-post-ajax'
        end

        it 'assigns the proper page transitions' do
            @browser.load( @url + '/visit_links' ).start_capture.visit_links

            pages = @browser.page_snapshots

            pages[0].transitions.should == [
                {:page=>:load},
                { @url + 'visit_links' => :request }
            ]
            pages[1].transitions == [
                {:page=>:load},
                {"<a href=\"javascript:inHref();\">"=>:click},
                {"#{@url}href-ajax"=>:request},
                {"#{@url}href-ajax"=>:request}
            ]
        end

        it 'returns self' do
            @browser.load( @url + '/visit_links' ).visit_links.should == @browser
        end
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

    describe '#goto' do
        it 'loads the given URL' do
            @browser.goto @url

            ua = Arachni::Options.user_agent
            ua.should_not be_empty

            @browser.source.should include( ua )
        end

        context 'when the take_snapshot argument has been set to' do
            describe true do
                it 'captures a snapshot of the loaded page' do
                    @browser.goto @url, true
                    pages = @browser.page_snapshots
                    pages.size.should == 1

                    pages.first.transitions.should == [
                        { page: :load },
                        { @url => :request }
                    ]
                end
            end

            describe false do
                it 'does not capture a snapshot of the loaded page' do
                    @browser.goto @url, false
                    @browser.page_snapshots.should be_empty
                end
            end

            describe 'default' do
                it 'captures a snapshot of the loaded page' do
                    @browser.goto @url
                    pages = @browser.page_snapshots
                    pages.size.should == 1

                    pages.first.transitions.should == [
                        { page: :load },
                        { @url => :request }
                    ]
                end
            end
        end

        it 'uses the system cookies' do
            url = @url + '/cookie-test'
            Arachni::HTTP::Client.cookie_jar << Arachni::Cookie.new(
                url:    @url,
                inputs: { 'cookie-name' => 'value' }
            )

            @browser.goto url
            @browser.watir.div( id: 'cookies' ).text.should ==
                "{\"cookie-name\"=>\"value\"}"
        end

        it 'updates the system cookies' do
            Arachni::HTTP::Client.cookies.
                find { |cookie| cookie.name == 'update' }.should be_nil

            @browser.goto @url + '/update-cookies'

            Arachni::HTTP::Client.cookies.
                find { |cookie| cookie.name == 'update' }.should be_true
        end

        it 'accepts cookies set via JavaScript' do
            Arachni::HTTP::Client.cookies.
                find { |cookie| cookie.name == 'js-cookie-name' }.should be_nil

            @browser.goto @url + '/set-javascript-cookie'

            Arachni::HTTP::Client.cookies.
                find { |cookie| cookie.name == 'js-cookie-name' }.should be_true

            @browser.to_page.cookies.
                find { |cookie| cookie.name == 'js-cookie-name' }.should be_true
        end

        it 'returns self' do
            @browser.goto( @url ).should == @browser
        end
    end

    describe '#load' do
        it 'returns self' do
            @browser.load( @url ).should == @browser
        end

        context 'when the take_snapshot argument has been set to' do
            describe true do
                it 'captures a snapshot of the loaded page' do
                    @browser.load @url, true
                    pages = @browser.page_snapshots
                    pages.size.should == 1

                    pages.first.transitions.should == [
                        { page: :load },
                        { @url => :request }
                    ]
                end
            end

            describe false do
                it 'does not capture a snapshot of the loaded page' do
                    @browser.load @url, false
                    @browser.page_snapshots.should be_empty
                end
            end

            describe 'default' do
                it 'captures a snapshot of the loaded page' do
                    @browser.load @url
                    pages = @browser.page_snapshots
                    pages.size.should == 1

                    pages.first.transitions.should == [
                        { page: :load },
                        { @url => :request }
                    ]
                end
            end
        end

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

                it 'uses its #cookiejar' do
                    @browser.cookies.should be_empty

                    page = Arachni::Page.from_data(
                        url:        @url,
                        cookiejar:  [
                            Arachni::Cookie.new(
                                url:    @url,
                                inputs: {
                                    'my-name' => 'my-value'
                                }
                            )
                        ]
                    )

                    @browser.load( page )
                    @browser.cookies.should == page.cookiejar
                end
            end

            describe 'other' do
                it 'raises Arachni::Browser::Error::Load' do
                    expect { @browser.load [] }.to raise_error Arachni::Browser::Error::Load
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

        it 'returns the URL of the resource' do
            response = Arachni::HTTP::Client.get( @url, mode: :sync )
            @browser.preload( response ).should == response.url

            @browser.load response.url
            @browser.source.should include( ua )
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

            describe 'other' do
                it 'raises Arachni::Browser::Error::Load' do
                    expect { @browser.preload [] }.to raise_error Arachni::Browser::Error::Load
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

        it 'returns the URL of the resource' do
            response = Arachni::HTTP::Client.get( @url, mode: :sync )
            @browser.cache( response ).should == response.url

            @browser.load response.url
            @browser.source.should include( ua )
            @browser.cache.should include( response.url )
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

            describe 'other' do
                it 'raises Arachni::Browser::Error::Load' do
                    expect { @browser.cache [] }.to raise_error Arachni::Browser::Error::Load
                end
            end

        end
    end

    describe '#start_capture' do
        it 'starts capturing requests and parses them into forms of pages' do
            @browser.start_capture
            @browser.load @url + '/with-ajax'

            pages = @browser.flush_pages
            pages.size.should == 2

            page = pages.first

            page.forms.find { |form| form.inputs.include? 'ajax-token' }.should be_true
        end

        context 'when a GET request is performed' do
            it 'is added as an Arachni::Form to the page' do
                @browser.start_capture
                @browser.load @url + '/with-ajax'

                pages = @browser.flush_pages
                pages.size.should == 2

                page = pages.first

                form = page.forms.find { |form| form.inputs.include? 'ajax-token' }

                form.url.should == @url + 'with-ajax'
                form.action.should == @url + 'get-ajax?ajax-token=my-token'
                form.inputs.should == { 'ajax-token' => 'my-token' }
                form.method.should == :get
                form.override_instance_scope?.should be_true
            end
        end

        context 'when a POST request is performed' do
            it 'is added as an Arachni::Form to the page' do
                @browser.start_capture
                @browser.load @url + '/with-ajax'

                pages = @browser.flush_pages
                pages.size.should == 2

                page = pages.first

                form = page.forms.find { |form| form.inputs.include? 'post-name' }

                form.url.should == @url + 'with-ajax'
                form.action.should == @url + 'post-ajax'
                form.inputs.should == { 'post-name' => 'post-value' }
                form.method.should == :post
                form.override_instance_scope?.should be_true
            end
        end
    end

    describe '#flush_pages' do
        it 'flushes the captured pages' do
            @browser.start_capture
            @browser.load @url + '/with-ajax'

            pages = @browser.flush_pages
            pages.size.should == 2
            @browser.flush_pages.should be_empty
        end
    end

    describe '#stop_capture' do
        it 'stops the page capture' do
            @browser.start_capture
            @browser.load @url + '/with-ajax'
            @browser.load @url + '/with-image'

            @browser.flush_pages.size.should == 4

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
            @browser.load @url
            @browser.cookies.size.should == 1
            cookie = @browser.cookies.first

            cookie.should be_kind_of Arachni::Cookie
            cookie.name.should == 'This name should be updated; and properly escaped'
            cookie.value.should == 'This value should be updated; and properly escaped'
        end
    end

end
