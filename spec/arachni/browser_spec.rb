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
        @browser.shutdown
        clear_hit_count
    end

    let( :ua ) { Arachni::Options.http.user_agent }

    def hit_count
        Typhoeus::Request.get( "#{@url}/hit-count" ).body.to_i
    end

    def clear_hit_count
        Typhoeus::Request.get( "#{@url}/clear-hit-count" )
    end

    def find_page_with_form_with_input( pages, input_name )
        pages.find do |page|
            page.forms.find { |form| form.inputs.include? input_name }
        end
    end

    def pages_should_have_form_with_input( pages, input_name )
        find_page_with_form_with_input( pages, input_name ).should be_true
    end

    def pages_should_not_have_form_with_input( pages, input_name )
        find_page_with_form_with_input( pages, input_name ).should be_false
    end

    it 'keeps track of setTimeout() timers' do
        @browser.load( @url + 'timeout-tracker' )
        @browser.timeouts.should == [
            [
                "function (name, value) {\n            document.cookie = name + \"=post-\" + value;\n        }",
                1000, 'timeout1', 1000
            ],
            [
                "function (name, value) {\n            document.cookie = name + \"=post-\" + value;\n        }",
                1500, 'timeout2', 1500
            ],
            [
                "function (name, value) {\n            document.cookie = name + \"=post-\" + value;\n        }",
                2000, 'timeout3', 2000
            ]
        ]

        @browser.load_delay.should == 2000
        @browser.cookies.size.should == 4
        @browser.cookies.map { |c| c.to_s }.sort.should == [
            'timeout3=post-2000',
            'timeout2=post-1500',
            'timeout1=post-1000',
            'timeout=pre'
        ].sort
    end

    it 'keeps track of setInterval() timers' do
        @browser.load( @url + 'interval-tracker' )
        @browser.intervals.should == [
            [
                "function (name, value) {\n            document.cookie = name + \"=post-\" + value;\n        }",
                2000, 'timeout1', 2000
            ]
        ]

        sleep 2
        @browser.cookies.size.should == 2
        @browser.cookies.map { |c| c.to_s }.sort.should == [
            'timeout1=post-2000',
            'timeout=pre'
        ].sort
    end

    it 'keeps track of which events are expected by each element' do
        @browser.load( @url + 'event-tracker' )
        @browser.watir.buttons.first.events.should == [
            [
                :click,
                "function handlerClick() {\n            document.getElementById( \"console\" ).innerHMTL += 'Clicked!';\n        }"
            ],
            [
                :onmouseover,
                "doStuff();"
            ]
        ]
    end

    it 'supports HTTPS' do
        url = web_server_url_for( :browser_https ).gsub( 'http', 'https' )

        @browser.start_capture
        pages = @browser.load( url ).flush_pages

        pages_should_have_form_with_input( pages, 'ajax-token' )
        pages_should_have_form_with_input( pages, 'by-ajax' )
    end

    describe '.events' do
        it 'returns all DOM events' do
            described_class.events.sort.should == [
                :onclick,
                :ondblclick,
                :onmousedown,
                :onmousemove,
                :onmouseout,
                :onmouseover,
                :onmouseup,
                :onload,
                :onsubmit,
                :onreset,
                :onselect,
                :onchange,
                :onfocus,
                :onblur,
                :onkeydown,
                :onkeypress,
                :onkeyup
            ].sort
        end
    end

    describe '#initialize' do
        describe :store_pages do
            describe 'default' do
                it 'stores snapshot pages' do
                    @browser.shutdown
                    @browser = described_class.new
                    @browser.load( @url + '/explore' ).flush_pages.should be_any
                end

                it 'stores captured pages' do
                    @browser.shutdown
                    @browser = described_class.new
                    @browser.start_capture
                    @browser.load( @url + '/with-ajax' ).flush_pages.should be_any
                end
            end

            describe true do
                it 'stores snapshot pages' do
                    @browser.shutdown
                    @browser = described_class.new( store_pages: true )
                    @browser.load( @url + '/explore' ).trigger_events.flush_pages.should be_any
                end

                it 'stores captured pages' do
                    @browser.shutdown
                    @browser = described_class.new( store_pages: true )
                    @browser.start_capture
                    @browser.load( @url + '/with-ajax' ).flush_pages.should be_any
                end
            end

            describe false do
                it 'stores snapshot pages' do
                    @browser.shutdown
                    @browser = described_class.new( store_pages: false )
                    @browser.load( @url + '/explore' ).trigger_events.flush_pages.should be_empty
                end

                it 'stores captured pages' do
                    @browser.shutdown
                    @browser = described_class.new( store_pages: false )
                    @browser.start_capture
                    @browser.load( @url + '/with-ajax' ).flush_pages.should be_empty
                end
            end
        end
    end

    describe '#debugging_data' do
        it 'returns debugging information' do
            @browser.load "#{@url}/debugging_data?input=_#{@browser.js_token}.debug(1)"
            @browser.watir.form.submit
            debugging_data = @browser.debugging_data

            first_entry = debugging_data.first
            debugging_data.should == [first_entry]

            first_entry[:data].should == [1]
            first_entry[:trace].size.should == 2
            first_entry[:trace][0][:function].should start_with 'function onClick'
            first_entry[:trace][0][:arguments].should == %w(some-arg arguments-arg here-arg)
            first_entry[:trace][1][:function].should start_with 'function onsubmit'

            first_entry[:trace][1][:arguments].size.should == 1
            event = first_entry[:trace][1][:arguments].first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            event['target'].should == form
            event['srcElement'].should == form
            event['type'].should == 'submit'
        end
    end

    describe '#sink' do
        it 'returns sink data' do
            @browser.load "#{@url}/debugging_data?input=_#{@browser.js_token}.send_to_sink(1)"
            @browser.watir.form.submit
            sink_data = @browser.sink

            first_entry = sink_data.first
            sink_data.should == [first_entry]

            first_entry[:data].should == [1]
            first_entry[:trace].size.should == 2
            first_entry[:trace][0][:function].should start_with 'function onClick'
            first_entry[:trace][0][:arguments].should == %w(some-arg arguments-arg here-arg)
            first_entry[:trace][1][:function].should start_with 'function onsubmit'

            first_entry[:trace][1][:arguments].size.should == 1
            event = first_entry[:trace][1][:arguments].first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            event['target'].should == form
            event['srcElement'].should == form
            event['type'].should == 'submit'
        end
    end

    describe '#flush_sink' do
        it 'returns sink data' do
            @browser.load "#{@url}/debugging_data?input=_#{@browser.js_token}.send_to_sink(1)"
            @browser.watir.form.submit
            sink_data = @browser.flush_sink

            first_entry = sink_data.first
            sink_data.should == [first_entry]

            first_entry[:data].should == [1]
            first_entry[:trace].size.should == 2
            first_entry[:trace][0][:function].should start_with 'function onClick'
            first_entry[:trace][0][:arguments].should == %w(some-arg arguments-arg here-arg)
            first_entry[:trace][1][:function].should start_with 'function onsubmit'

            first_entry[:trace][1][:arguments].size.should == 1
            event = first_entry[:trace][1][:arguments].first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            event['target'].should == form
            event['srcElement'].should == form
            event['type'].should == 'submit'
        end

        it 'empties the sink' do
            @browser.load "#{@url}/debugging_data?input=_#{@browser.js_token}.send_to_sink(1)"
            @browser.watir.form.submit
            @browser.flush_sink
            @browser.sink.should be_empty
        end
    end

    describe '#page_snapshots_with_sinks' do
        it 'returns sink data' do
            @browser.load "#{@url}/lots_of_sinks?input=_#{@browser.js_token}.send_to_sink(1)"
            @browser.explore_and_flush
            doms = @browser.page_snapshots_with_sinks.map(&:dom)

            doms.size.should == 2

            doms[0].transitions.should == [
                { page: :load },
                { "#{@url}lots_of_sinks?input=_#{@browser.js_token}.send_to_sink(1)" => :request },
                { "<a href=\"#\" onmouseover=\"onClick2('blah1', 'blah2', 'blah3');\">" => :onmouseover }
            ]

            doms[0].sink.size.should == 2

            entry = doms[0].sink[0]
            entry[:data].should == [1]
            entry[:trace].size.should == 3
            entry[:trace][0][:function].should start_with 'function onClick'
            entry[:trace][0][:arguments].should == [1, 2]

            entry[:trace][1][:function].should start_with 'function onClick2'
            entry[:trace][1][:arguments].should == ["blah1", "blah2", "blah3"]

            entry[:trace][2][:function].should start_with 'function onmouseover'

            event = entry[:trace][2][:arguments].first

            link = "<a href=\"#\" onmouseover=\"onClick2('blah1', 'blah2', 'blah3');\">Blah</a>"
            event['target'].should == link
            event['srcElement'].should == link
            event['type'].should == 'mouseover'

            entry = doms[0].sink[1]
            entry[:data].should == [1]
            entry[:trace].size.should == 4

            entry[:trace][0][:function].should start_with 'function onClick3'
            entry[:trace][0][:arguments].should be_empty

            entry[:trace][1][:function].should start_with 'function onClick'
            entry[:trace][1][:arguments].should == [1, 2]

            entry[:trace][2][:function].should start_with 'function onClick2'
            entry[:trace][2][:arguments].should == ["blah1", "blah2", "blah3"]

            entry[:trace][3][:function].should start_with 'function onmouseover'

            event = entry[:trace][3][:arguments].first

            link = "<a href=\"#\" onmouseover=\"onClick2('blah1', 'blah2', 'blah3');\">Blah</a>"
            event['target'].should == link
            event['srcElement'].should == link
            event['type'].should == 'mouseover'

            doms[1].transitions.should == [
                { page: :load },
                { "#{@url}lots_of_sinks?input=_#{@browser.js_token}.send_to_sink(1)" => :request },
                { "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">" => :onsubmit }
            ]

            doms[1].sink.size.should == 2

            entry = doms[1].sink[0]
            entry[:data].should == [1]
            entry[:trace].size.should == 2
            entry[:trace][0][:function].should start_with 'function onClick'
            entry[:trace][0][:arguments].should == %w(some-arg arguments-arg here-arg)

            entry[:trace][1][:function].should start_with 'function onsubmit'

            event = entry[:trace][1][:arguments].first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            event['target'].should == form
            event['srcElement'].should == form
            event['type'].should == 'submit'

            entry = doms[1].sink[1]
            entry[:data].should == [1]
            entry[:trace].size.should == 3
            entry[:trace][0][:function].should start_with 'function onClick3'
            entry[:trace][0][:arguments].should be_empty

            entry[:trace][1][:function].should start_with 'function onClick'
            entry[:trace][1][:arguments].should == %w(some-arg arguments-arg here-arg)

            entry[:trace][2][:function].should start_with 'function onsubmit'

            event = entry[:trace][2][:arguments].first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            event['target'].should == form
            event['srcElement'].should == form
            event['type'].should == 'submit'
        end

        describe 'when store_pages: false' do
            it 'does not store pages' do
                @browser.shutdown
                @browser = described_class.new( store_pages: false )
                @browser.load "#{@url}/lots_of_sinks?input=_#{@browser.js_token}.send_to_sink(1)"
                @browser.explore_and_flush
                @browser.page_snapshots_with_sinks.should be_empty
            end
        end
    end

    describe '#flush_page_snapshots_with_sinks' do
        it 'returns sink data' do
            @browser.load "#{@url}/lots_of_sinks?input=_#{@browser.js_token}.send_to_sink(1)"
            @browser.explore_and_flush
            @browser.page_snapshots_with_sinks.map(&:dom).map(&:sink).should ==
                @browser.flush_page_snapshots_with_sinks.map(&:dom).map(&:sink)
        end

        it 'empties the buffer' do
            @browser.load "#{@url}/lots_of_sinks?input=_#{@browser.js_token}.send_to_sink(1)"
            @browser.explore_and_flush
            @browser.flush_page_snapshots_with_sinks.map(&:dom).map(&:sink)
            @browser.page_snapshots_with_sinks.should be_empty
        end
    end

    describe '#on_new_page_with_sink' do
        it 'assigns blocks to handle each page with sink data' do
            @browser.load "#{@url}/lots_of_sinks?input=_#{@browser.js_token}.send_to_sink(1)"

            sinks = []
            @browser.on_new_page_with_sink do |page|
                sinks << page.dom.sink
            end

            @browser.explore_and_flush

            sinks.size.should == 2
            sinks.should == @browser.page_snapshots_with_sinks.map(&:dom).map(&:sink)
        end
    end

    describe '#execute_script' do
        it 'executes the given script under the browser\'s context' do
            @browser.load @url
            Nokogiri::HTML(@browser.source).to_s.should ==
                Nokogiri::HTML(@browser.execute_script( 'return document.documentElement.innerHTML' ) ).to_s
        end
    end

    describe '#on_new_page' do
        it 'is passed each snapshot' do
            pages = []
            @browser.on_new_page { |page| pages << page }

            @browser.load( @url + '/explore' ).trigger_events.
                page_snapshots.should == pages
        end

        it 'is passed each request capture' do
            pages = []
            @browser.on_new_page { |page| pages << page }
            @browser.start_capture

            # Last page will be the root snapshot so ignore it.
            @browser.load( @url + '/with-ajax' ).captured_pages.should == pages[0...2]
        end
    end

    describe '#on_response' do
        context 'when a response is preloaded' do
            it 'is passed each response' do
                responses = []
                @browser.on_response { |response| responses << response }

                @browser.preload Arachni::HTTP::Client.get( @url, mode: :sync )
                @browser.goto @url

                response = responses.first
                response.should be_kind_of Arachni::HTTP::Response
                response.url.should == @url
            end
        end

        context 'when a response is cached' do
            it 'is passed each response' do
                responses = []
                @browser.on_response { |response| responses << response }

                @browser.cache Arachni::HTTP::Client.get( @url, mode: :sync )
                @browser.goto @url

                response = responses.first
                response.should be_kind_of Arachni::HTTP::Response
                response.url.should == @url
            end
        end

        context 'when a request is performed by the browser' do
            it 'is passed each response' do
                responses = []
                @browser.on_response { |response| responses << response }

                @browser.goto @url

                response = responses.first
                response.should be_kind_of Arachni::HTTP::Response
                response.url.should == @url
            end
        end
    end

    describe '#explore_and_flush' do
        it 'handles deep DOM/page transitions' do
            pages = @browser.load( @url + '/deep-dom' ).explore_and_flush

            pages_should_have_form_with_input pages, 'by-ajax'

            pages.map(&:dom).map(&:transitions).should == [
                [
                    { :page => :load },
                    { "#{@url}deep-dom" => :request },
                    { "#{@url}level2" => :request }
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
                    { "<a onmouseover=\"writeButton();\" href=\"javascript:level3();\">" => :click },
                    { "#{@url}level4" => :request }
                ],
                [
                    { :page => :load },
                    { "#{@url}deep-dom" => :request },
                    { "#{@url}level2" => :request },
                    { "<a onmouseover=\"writeButton();\" href=\"javascript:level3();\">" => :onmouseover },
                    { "<button onclick=\"writeUserAgent();\">" => :onclick }
                ],
                [
                    { :page => :load },
                    { "#{@url}deep-dom" => :request },
                    { "#{@url}level2" => :request },
                    { "<a onmouseover=\"writeButton();\" href=\"javascript:level3();\">" => :click },
                    { "#{@url}level4" => :request },
                    { "<div onclick=\"level6();\" id=\"level5\">" => :onclick },
                    { "#{@url}level6" => :request }
                ]
            ]
        end

        context 'with a depth argument' do
            it 'does not go past the given DOM depth' do
                pages = @browser.load( @url + '/deep-dom' ).explore_and_flush(2)

                pages.map(&:dom).map(&:transitions).should == [
                    [
                        { :page => :load },
                        { "#{@url}deep-dom" => :request },
                        { "#{@url}level2" => :request }
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
                        { "<a onmouseover=\"writeButton();\" href=\"javascript:level3();\">" => :click },
                        { "#{@url}level4" => :request }
                    ]
                ]
            end
        end

    end

    describe '#to_page' do
        it 'converts the working window to an Arachni::Page' do
            ua = Arachni::Options.http.user_agent

            @browser.load( @url )
            page = @browser.to_page

            page.should be_kind_of Arachni::Page

            ua.should_not be_empty
            page.response.body.should_not include( ua )
            page.body.should include( ua )
        end

        it 'assigns the proper page transitions' do
            @browser.load( @url )
            page = @browser.to_page

            page.dom.transitions.should == [
                { page: :load },
                { @url => :request }
            ]
        end

        it 'assigns the proper sink data' do
            @browser.load "#{@url}/debugging_data?input=_#{@browser.js_token}.send_to_sink(1)"
            @browser.watir.form.submit

            page = @browser.to_page
            sink_data = page.dom.sink

            first_entry = sink_data.first
            sink_data.should == [first_entry]

            first_entry[:data].should == [1]
            first_entry[:trace].size.should == 2
            first_entry[:trace][0][:function].should start_with 'function onClick'
            first_entry[:trace][0][:arguments].should == %w(some-arg arguments-arg here-arg)
            first_entry[:trace][1][:function].should start_with 'function onsubmit'

            first_entry[:trace][1][:arguments].size.should == 1
            event = first_entry[:trace][1][:arguments].first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            event['target'].should == form
            event['srcElement'].should == form
            event['type'].should == 'submit'
        end
    end

    describe '#fire_event' do
        it 'fires the given event' do
            @browser.load( @url + '/trigger_events' ).start_capture
            @browser.fire_event @browser.watir.div( id: 'my-div' ), :onclick
            pages_should_have_form_with_input [@browser.to_page], 'by-ajax'
        end
    end

    describe '#each_element_with_events' do
        it 'passes each element and event info to the block' do
            @browser.load( @url + '/trigger_events' ).start_capture

            elements_with_events = []
            @browser.each_element_with_events do |info|
                elements_with_events << info
            end

            elements_with_events.should == [
                { index: 4, tag_name: 'body', events: [[:onmouseover, 'makePOST();']] },
                { index: 5, tag_name: 'div', events: [[:onclick, 'addForm();']] }
            ]
        end

        it 'skips invisible elements' do
            @browser.load( @url + '/skip-invisible-elements' ).start_capture

            elements_with_events = []
            @browser.each_element_with_events do |info|
                elements_with_events << info
            end

            elements_with_events.should be_any

            @browser.execute_script( "document.getElementById('my-button').style.visibility='none'" )

            elements_with_events = []
            @browser.each_element_with_events do |info|
                elements_with_events << info
            end

            elements_with_events.should be_empty
        end
    end

    describe '#trigger_event' do
        it 'triggers the given event and captures snapshots' do
            @browser.load( @url + '/trigger_events' ).start_capture

            @browser.watir.elements.each.with_index do |_, index|
                described_class.events.each do |e|
                    @browser.trigger_event @browser.to_page, index, e
                end
            end

            pages_should_have_form_with_input @browser.page_snapshots, 'by-ajax'
            pages_should_have_form_with_input @browser.captured_pages, 'ajax-token'
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
            pages_should_have_form_with_input @browser.captured_pages, 'post-name'
        end

        it 'assigns the proper page transitions' do
            pages = @browser.load( @url + '/explore' ).trigger_events.page_snapshots

            transitions = pages.map(&:dom).map(&:transitions)

            transitions.should == [
                [
                    { :page => :load },
                    { "#{@url}explore" => :request }
                ],
                [
                    { :page => :load },
                    { "#{@url}explore" => :request },
                    { "<div id=\"my-div\" onclick=\"addForm();\">" => :onclick },
                    { "#{@url}post-ajax" => :request },
                    { "#{@url}get-ajax?ajax-token=my-token" => :request }
                ],
                [
                    { :page => :load },
                    { "#{@url}explore" => :request },
                    { "<a href=\"javascript:inHref();\">" => :click }
                ]
            ]
        end

        it 'ignores differences in text nodes' do
            url = @url + '/ever-changing'

            @browser.load( url ).trigger_events
            @browser.page_snapshots.size.should == 1

            @browser.load( url ).trigger_events
            @browser.page_snapshots.size.should == 1
        end

        it 'ignores differences in text nodes performed via JS' do
            url = @url + '/ever-changing-via-js'

            @browser.load( url ).trigger_events
            @browser.page_snapshots.size.should == 1

            @browser.load( url ).trigger_events
            @browser.page_snapshots.size.should == 1
        end

        it 'follows all javascript links' do
            @browser.load( @url + '/explore' ).start_capture.trigger_events

            pages_should_have_form_with_input @browser.page_snapshots, 'by-ajax'
            pages_should_have_form_with_input @browser.page_snapshots, 'from-post-ajax'
            pages_should_have_form_with_input @browser.captured_pages, 'ajax-token'
            pages_should_have_form_with_input @browser.captured_pages, 'href-post-name'
        end

        it 'captures pages from new windows' do
            pages = @browser.load( @url + '/explore-new-window' ).
                start_capture.trigger_events.flush_pages

            pages_should_have_form_with_input pages, 'in-old-window'
            pages_should_have_form_with_input pages, 'in-new-window'
        end

        context 'when submitting forms using an image input' do
            it 'includes x, y coordinates' do
                @browser.load( "#{@url}form-with-image-button" ).start_capture.trigger_events
                pages_should_have_form_with_input @browser.captured_pages, 'myImageButton.x'
                pages_should_have_form_with_input @browser.captured_pages, 'myImageButton.y'
            end
        end

        it 'returns self' do
            @browser.load( @url + '/explore' ).trigger_events.should == @browser
        end
    end

    describe '#source' do
        it 'returns the evaluated HTML source' do
            @browser.load @url

            ua = Arachni::Options.http.user_agent
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

            ua = Arachni::Options.http.user_agent
            ua.should_not be_empty

            @browser.source.should include( ua )
        end

        context 'when Options#scope_exclude_path_patterns has bee configured' do
            it 'respects scope restrictions' do
                pages = @browser.load( @url + '/explore' ).start_capture.trigger_events.page_snapshots
                pages_should_have_form_with_input pages, 'by-ajax'

                @browser.shutdown
                @browser = described_class.new

                Arachni::Options.scope.exclude_path_patterns << /ajax/

                pages = @browser.load( @url + '/explore' ).start_capture.trigger_events.page_snapshots
                pages_should_not_have_form_with_input pages, 'by-ajax'
            end
        end

        context 'when Options#scope_redundant_path_patterns has bee configured' do
            it 'respects scope restrictions' do
                Arachni::Options.scope.redundant_path_patterns = { 'explore' => 3 }

                @browser.load( @url + '/explore' ).response.code.should == 200

                2.times do
                    @browser.load( @url + '/explore' ).response.code.should == 200
                end

                @browser.load( @url + '/explore' ).response.code.should == 0
            end
        end

        context 'when Options#scope_auto_redundant_paths has bee configured' do
            it 'respects scope restrictions' do
                Arachni::Options.scope.auto_redundant_paths = 3

                @browser.load( @url + '/explore?test=1&test2=2' ).response.code.should == 200

                2.times do
                    @browser.load( @url + '/explore?test=1&test2=2' ).response.code.should == 200
                end

                @browser.load( @url + '/explore?test=1&test2=2' ).response.code.should == 0
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

        context 'when the take_snapshot argument has been set to' do
            describe true do
                it 'captures a snapshot of the loaded page' do
                    @browser.goto @url, true
                    pages = @browser.page_snapshots
                    pages.size.should == 1

                    pages.first.dom.transitions.should == [
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

                    pages.first.dom.transitions.should == [
                        { page: :load },
                        { @url => :request }
                    ]
                end
            end
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

                    pages.first.dom.transitions.should == [
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

                    pages.first.dom.transitions.should == [
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

                it 'replays its transitions' do
                    @browser.load "#{@url}replay-transitions"
                    page = @browser.explore_and_flush.last
                    page.body.should include ua

                    @browser.load page
                    @browser.source.should include ua

                    page.dom.transitions.clear
                    @browser.load page
                    @browser.source.should_not include ua
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
            pages.size.should == 3

            page = pages.first

            page.forms.find { |form| form.inputs.include? 'ajax-token' }.should be_true
        end

        context 'when a GET request is performed' do
            it 'is added as an Arachni::Form to the page' do
                @browser.start_capture
                @browser.load @url + '/with-ajax'

                pages = @browser.flush_pages
                pages.size.should == 3

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
                pages.size.should == 3

                form = find_page_with_form_with_input( pages, 'post-name' ).
                    forms.find { |form| form.inputs.include? 'post-name' }

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
            pages.size.should == 3
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
            @browser.flush_pages.size.should == 2
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
