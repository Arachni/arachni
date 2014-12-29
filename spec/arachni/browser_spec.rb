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

    let(:subject) { @browser }
    let(:ua) { Arachni::Options.http.user_agent }

    def transitions_from_array( transitions )
        transitions.map do |t|
            element, event = t.first.to_a

            options = {}
            if element == :page && event == :load
                options.merge!( url: @browser.watir.url, cookies: {} )
            end

            if element.is_a? Hash
                element = described_class::ElementLocator.new( element )
            end

            Arachni::Page::DOM::Transition.new( element, event, options ).complete
        end
    end

    def hit_count
        Typhoeus::Request.get( "#{@url}/hit-count" ).body.to_i
    end

    def clear_hit_count
        Typhoeus::Request.get( "#{@url}/clear-hit-count" )
    end

    it 'supports HTTPS' do
        url = web_server_url_for( :browser_https )

        @browser.start_capture
        pages = @browser.load( url ).flush_pages

        pages_should_have_form_with_input( pages, 'ajax-token' )
        pages_should_have_form_with_input( pages, 'by-ajax' )
    end

    describe '.has_executable?' do
        context 'when there is no executable browser' do
            it 'returns false' do
                Selenium::WebDriver::PhantomJS.stub(:path){ false }
                described_class.has_executable?.should be_false
            end
        end

        context 'when there is an executable browser' do
            it 'returns true' do
                Selenium::WebDriver::PhantomJS.stub(:path){ __FILE__ }
                described_class.has_executable?.should be_true
            end
        end
    end

    describe '.executable' do
        it 'returns the path to the browser executable' do
            stub = __FILE__
            Selenium::WebDriver::PhantomJS.stub(:path){ stub }
            described_class.executable.should == stub
        end
    end

    describe '#initialize' do
        describe :concurrency do
            it 'sets the HTTP request concurrency'
        end

        describe :ignore_scope do
            context true do
                it 'ignores scope restrictions' do
                    @browser.shutdown

                    @browser = described_class.new( ignore_scope: true )

                    Arachni::Options.scope.exclude_path_patterns << /sleep/

                    subject.load @url + '/ajax_sleep'
                    subject.to_page.should be_true
                end
            end

            context false do
                it 'enforces scope restrictions' do
                    @browser.shutdown

                    @browser = described_class.new( ignore_scope: false )

                    Arachni::Options.scope.exclude_path_patterns << /sleep/

                    subject.load @url + '/ajax_sleep'
                    subject.to_page.code.should == 0
                end
            end

            context :default do
                it 'enforces scope restrictions' do
                    @browser.shutdown

                    @browser = described_class.new( ignore_scope: false )

                    Arachni::Options.scope.exclude_path_patterns << /sleep/

                    subject.load @url + '/ajax_sleep'
                    subject.to_page.code.should == 0
                end
            end
        end

        describe :width do
            it 'sets the window width' do
                @browser.shutdown

                width = 100
                @browser = described_class.new( width: width )
                subject.javascript.run('return window.innerWidth').should == width
            end

            it 'defaults to 1600' do
                subject.javascript.run('return window.innerWidth').should == 1600
            end
        end

        describe :height do
            it 'sets the window height' do
                @browser.shutdown

                height = 100
                @browser = described_class.new( height: height )
                subject.javascript.run('return window.innerHeight').should == height
            end

            it 'defaults to 1200' do
                subject.javascript.run('return window.innerHeight').should == 1200
            end
        end

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

        context 'when browser process spawn fails' do
            it "raises #{described_class::Error::Spawn}" do
                described_class.any_instance.stub(:spawn_phantomjs) { nil }
                expect { described_class.new }.to raise_error described_class::Error::Spawn
            end
        end
    end

    describe '#source_with_line_numbers' do
        it 'prefixes each source code line with a number' do
            subject.load @url

            lines = subject.source.lines.to_a

            lines.should be_any
            subject.source_with_line_numbers.lines.each.with_index do |l, i|
                l.should == "#{i+1} - #{lines[i]}"
            end
        end
    end

    describe '#load_delay' do
        it 'returns nil' do
            subject.load @url
            subject.load_delay.should be_nil
        end

        context 'when the page has JS timeouts' do
            it 'returns the maximum time the browser should wait for the page based on Timeout' do
                subject.load( "#{@url}load_delay" )
                subject.load_delay.should == 2000
            end
        end
    end

    describe '#wait_for_timers' do
        it 'returns' do
            subject.load @url
            subject.wait_for_timers.should be_nil
        end

        context 'when the page has JS timeouts' do
            it 'waits for them to complete' do
                subject.load( "#{@url}load_delay" )
                seconds = subject.load_delay / 1000

                time = Time.now
                subject.wait_for_timers
                (Time.now - time).should > seconds
            end

            it "caps them at #{Arachni::OptionGroups::HTTP}#request_timeout" do
                subject.load( "#{@url}load_delay" )

                Arachni::Options.http.request_timeout = 100

                time = Time.now
                subject.wait_for_timers
                (Time.now - time).should < 0.2
            end
        end
    end

    describe '#capture_snapshot' do
        let(:sink_url) do
            "#{@url}script_sink?input=#{@browser.javascript.log_execution_flow_sink_stub(1)}"
        end
        let(:ajax_url) do
            "#{@url}with-ajax"
        end
        let(:captured) { subject.capture_snapshot }

        context 'when a snapshot has not been previously seen' do
            before :each do
                subject.load( @url + '/with-ajax', take_snapshot: false )
            end

            it 'calls #on_new_page callbacks' do
                received = []
                subject.on_new_page do |page|
                    received << page
                end

                captured.should == received
            end

            context '#store_pages?' do
                context true do
                    subject { @browser.shutdown; @browser = described_class.new( store_pages: true )}

                    it 'stores it in #page_snapshots' do
                        captured = subject.capture_snapshot

                        subject.page_snapshots.should == captured
                    end

                    it 'returns it' do
                        captured.size.should == 1
                        captured.first.should == subject.to_page
                    end
                end

                context false do
                    subject { @browser.shutdown; @browser = described_class.new( store_pages: false ) }

                    it 'does not store it' do
                        subject.capture_snapshot

                        subject.page_snapshots.should be_empty
                    end

                    it 'returns an empty array' do
                        captured.should be_empty
                    end
                end
            end
        end

        context 'when a snapshot has already been seen' do
            before :each do
                subject.load( @url + '/with-ajax', take_snapshot: false )
            end

            it 'ignores it' do
                subject.capture_snapshot.should be_any
                subject.capture_snapshot.should be_empty
            end
        end

        context 'when a snapshot has sink data' do
            before :each do
                subject.load sink_url, take_snapshot: false
            end

            it 'calls #on_new_page_with_sink callbacks' do
                sinks = []
                subject.on_new_page_with_sink do |page|
                    sinks << page.dom.execution_flow_sinks
                end

                subject.capture_snapshot

                sinks.size.should == 1
            end

            context 'and has already been seen' do
                it 'calls #on_new_page_with_sink callbacks' do
                    sinks = []
                    subject.on_new_page_with_sink do |page|
                        sinks << page.dom.execution_flow_sinks
                    end

                    subject.capture_snapshot
                    subject.capture_snapshot

                    sinks.size.should == 2
                end
            end

            context '#store_pages?' do
                context true do
                    subject { @browser.shutdown; @browser = described_class.new( store_pages: true )}

                    it 'stores it in #page_snapshots_with_sinks' do
                        subject.capture_snapshot
                        subject.page_snapshots_with_sinks.should be_any
                    end
                end

                context false do
                    subject { @browser.shutdown; @browser = described_class.new( store_pages: false )}

                    it 'does not store it in #page_snapshots_with_sinks' do
                        subject.capture_snapshot
                        subject.page_snapshots_with_sinks.should be_empty
                    end
                end
            end
        end

        context 'when a transition has been given' do
            before :each do
                subject.load( ajax_url, take_snapshot: false )
            end

            it 'pushes it to the existing transitions' do
                transition = { stuff: :here }
                captured = subject.capture_snapshot( stuff: :here )

                captured.first.dom.transitions.should include transition
            end
        end

        context 'when there are multiple windows open' do
            before :each do
                subject.load( ajax_url, take_snapshot: false )
            end

            it 'captures snapshots from all windows' do
                subject.javascript.run( 'window.open()' )
                subject.watir.windows.last.use
                subject.load sink_url, take_snapshot: false

                subject.capture_snapshot.map(&:url).sort.should ==
                    [ajax_url, sink_url].sort
            end
        end

        context 'when an error occurs' do
            it 'ignores it' do
                subject.watir.stub(:windows) { raise }
                subject.capture_snapshot( blah: :stuff ).should be_empty
            end
        end
    end

    describe '#flush_page_snapshots_with_sinks' do
        it 'returns pages with data-flow sink data' do
            @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_data_flow_sink_stub( function: { name: 'blah' } )}"
            @browser.explore_and_flush
            @browser.page_snapshots_with_sinks.map(&:dom).map(&:data_flow_sinks).should ==
                @browser.flush_page_snapshots_with_sinks.map(&:dom).map(&:data_flow_sinks)
        end

        it 'returns pages with execution-flow sink data' do
            @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_execution_flow_sink_stub( function: { name: 'blah' } )}"
            @browser.explore_and_flush
            @browser.page_snapshots_with_sinks.map(&:dom).map(&:execution_flow_sinks).should ==
                @browser.flush_page_snapshots_with_sinks.map(&:dom).map(&:execution_flow_sinks)
        end

        it 'empties the data-flow sink page buffer' do
            @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_data_flow_sink_stub( function: { name: 'blah' } )}"
            @browser.explore_and_flush
            @browser.flush_page_snapshots_with_sinks.map(&:dom).map(&:data_flow_sinks)
            @browser.page_snapshots_with_sinks.should be_empty
        end

        it 'empties the execution-flow sink page buffer' do
            @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_execution_flow_sink_stub( function: { name: 'blah' } )}"
            @browser.explore_and_flush
            @browser.flush_page_snapshots_with_sinks.map(&:dom).map(&:execution_flow_sinks)
            @browser.page_snapshots_with_sinks.should be_empty
        end
    end

    describe '#on_new_page_with_sink' do
        it 'assigns blocks to handle each page with execution-flow sink data' do
            @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_execution_flow_sink_stub( function: { name: 'blah' } )}"

            sinks = []
            @browser.on_new_page_with_sink do |page|
                sinks << page.dom.execution_flow_sinks
            end

            @browser.explore_and_flush

            sinks.size.should == 2
            sinks.should == @browser.page_snapshots_with_sinks.map(&:dom).
                map(&:execution_flow_sinks)
        end

        it 'assigns blocks to handle each page with data-flow sink data' do
            @browser.javascript.taint = 'taint'
            @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_data_flow_sink_stub( @browser.javascript.taint, function: { name: 'blah' } )}"

            sinks = []
            @browser.on_new_page_with_sink do |page|
                sinks << page.dom.data_flow_sinks
            end

            @browser.explore_and_flush

            sinks.size.should == 2
            sinks.should == @browser.page_snapshots_with_sinks.map(&:dom).
                map(&:data_flow_sinks)
        end
    end

    describe '#on_fire_event' do
        it 'gets called before each event is triggered' do
            @browser.load "#{@url}/trigger_events"

            calls = []
            @browser.on_fire_event do |element, event|
                calls << [element.opening_tag, event]
            end

            @browser.fire_event @browser.watir.div( id: 'my-div' ), :click
            @browser.fire_event @browser.watir.div( id: 'my-div' ), :mouseover

            calls.should == [
                [ "<div id=\"my-div\" onclick=\"addForm();\">", :click ],
                [ "<div id=\"my-div\" onclick=\"addForm();\">", :mouseover ]
            ]
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
            url = @url + '/deep-dom'
            pages = @browser.load( url ).explore_and_flush

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
                    {
                        {
                            tag_name: 'a',
                            attributes: {
                                'onmouseover' => 'writeButton();',
                                'href'        => 'javascript:level3();'
                            }
                        } => :mouseover
                    }
                ],
                [
                    { :page => :load },
                    { "#{@url}deep-dom" => :request },
                    { "#{@url}level2" => :request },
                    {
                        {
                            tag_name: 'a',
                            attributes: {
                                'onmouseover' => 'writeButton();',
                                'href'        => 'javascript:level3();'
                            }
                        } => :click
                    },
                    { "#{@url}level4" => :request }
                ],
                [
                    { :page => :load },
                    { "#{@url}deep-dom" => :request },
                    { "#{@url}level2" => :request },
                    {
                        {
                            tag_name: 'a',
                            attributes: {
                                'onmouseover' => 'writeButton();',
                                'href'        => 'javascript:level3();'
                            }
                        } => :mouseover
                    },
                    {
                        {
                            tag_name: 'button',
                            attributes: {
                                'onclick' => 'writeUserAgent();',
                            }
                        } => :click
                    }
                ],
                [
                    { :page => :load },
                    { "#{@url}deep-dom" => :request },
                    { "#{@url}level2" => :request },
                    {
                        {
                            tag_name: 'a',
                            attributes: {
                                'onmouseover' => 'writeButton();',
                                'href'        => 'javascript:level3();'
                            }
                        } => :click
                    },
                    { "#{@url}level4" => :request },
                    {
                        {
                            tag_name: 'div',
                            attributes: {
                                'onclick' => 'level6();',
                                'id'      => 'level5'
                            }
                        } => :click
                    },

                    { "#{@url}level6" => :request }
                ]
            ].map { |transitions| transitions_from_array( transitions ) }
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
                        {
                            {
                                tag_name: 'a',
                                attributes: {
                                    'onmouseover' => 'writeButton();',
                                    'href'        => 'javascript:level3();'
                                }
                            } => :mouseover
                        }
                    ],
                    [
                        { :page => :load },
                        { "#{@url}deep-dom" => :request },
                        { "#{@url}level2" => :request },
                        {
                            {
                                tag_name: 'a',
                                attributes: {
                                    'onmouseover' => 'writeButton();',
                                    'href'        => 'javascript:level3();'
                                }
                            } => :click
                        },
                        { "#{@url}level4" => :request }
                    ]
                ].map { |transitions| transitions_from_array( transitions ) }
            end
        end
    end

    describe '#page_snapshots_with_sinks' do
        it 'returns execution-flow sink data' do
            @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_execution_flow_sink_stub(1)}"
            @browser.explore_and_flush

            pages = @browser.page_snapshots_with_sinks
            doms  = pages.map(&:dom)

            doms.size.should == 2

            doms[0].transitions.should == transitions_from_array([
                { page: :load },
                { "#{@url}lots_of_sinks?input=#{@browser.javascript.log_execution_flow_sink_stub(1)}" => :request },
                {
                    {
                        tag_name:   'a',
                        attributes: {
                            'href'        => '#',
                            'onmouseover' => "onClick2('blah1', 'blah2', 'blah3');"
                        }
                    } => :mouseover
                }
            ])

            doms[0].execution_flow_sinks.size.should == 2

            entry = doms[0].execution_flow_sinks[0]
            entry.data.should == [1]
            entry.trace.size.should == 3

            entry.trace[0].function.name.should == 'onClick'
            entry.trace[0].function.source.should start_with 'function onClick'
            @browser.source.split("\n")[entry.trace[0].line].should include 'log_execution_flow_sink(1)'
            entry.trace[0].function.arguments.should == [1, 2]

            entry.trace[1].function.name.should == 'onClick2'
            entry.trace[1].function.source.should start_with 'function onClick2'
            @browser.source.split("\n")[entry.trace[1].line].should include 'onClick'
            entry.trace[1].function.arguments.should == %w(blah1 blah2 blah3)

            entry.trace[2].function.name.should == 'onmouseover'
            entry.trace[2].function.source.should start_with 'function onmouseover'

            event = entry.trace[2].function.arguments.first

            link = "<a href=\"#\" onmouseover=\"onClick2('blah1', 'blah2', 'blah3');\">Blah</a>"
            event['target'].should == link
            event['srcElement'].should == link
            event['type'].should == 'mouseover'

            entry = doms[0].execution_flow_sinks[1]
            entry.data.should == [1]
            entry.trace.size.should == 4

            entry.trace[0].function.name.should == 'onClick3'
            entry.trace[0].function.source.should start_with 'function onClick3'
            @browser.source.split("\n")[entry.trace[0].line].should include 'log_execution_flow_sink(1)'
            entry.trace[0].function.arguments.should be_empty

            entry.trace[1].function.name.should == 'onClick'
            entry.trace[1].function.source.should start_with 'function onClick'
            @browser.source.split("\n")[entry.trace[1].line].should include 'onClick3'
            entry.trace[1].function.arguments.should == [1, 2]

            entry.trace[2].function.name.should == 'onClick2'
            entry.trace[2].function.source.should start_with 'function onClick2'
            @browser.source.split("\n")[entry.trace[2].line].should include 'onClick'
            entry.trace[2].function.arguments.should == %w(blah1 blah2 blah3)

            entry.trace[3].function.name.should == 'onmouseover'
            entry.trace[3].function.source.should start_with 'function onmouseover'

            event = entry.trace[3].function.arguments.first

            link = "<a href=\"#\" onmouseover=\"onClick2('blah1', 'blah2', 'blah3');\">Blah</a>"
            event['target'].should == link
            event['srcElement'].should == link
            event['type'].should == 'mouseover'

            doms[1].transitions.should == transitions_from_array([
                { page: :load },
                { "#{@url}lots_of_sinks?input=#{@browser.javascript.log_execution_flow_sink_stub(1)}" => :request },
                {
                    {
                        tag_name:   'form',
                        attributes: {
                            'id'       => 'my_form',
                            'onsubmit' => "onClick('some-arg', 'arguments-arg', 'here-arg'); return false;"
                        }
                    } => :submit
                }
            ])

            doms[1].execution_flow_sinks.size.should == 2

            entry = doms[1].execution_flow_sinks[0]
            entry.data.should == [1]
            entry.trace.size.should == 2

            entry.trace[0].function.name.should == 'onClick'
            entry.trace[0].function.source.should start_with 'function onClick'
            @browser.source.split("\n")[entry.trace[0].line].should include 'log_execution_flow_sink(1)'
            entry.trace[0].function.arguments.should == %w(some-arg arguments-arg here-arg)

            entry.trace[1].function.name.should == 'onsubmit'
            entry.trace[1].function.source.should start_with 'function onsubmit'
            @browser.source.split("\n")[entry.trace[1].line].should include 'onClick'

            event = entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            event['target'].should == form
            event['srcElement'].should == form
            event['type'].should == 'submit'

            entry = doms[1].execution_flow_sinks[1]
            entry.data.should == [1]
            entry.trace.size.should == 3

            entry.trace[0].function.name.should == 'onClick3'
            entry.trace[0].function.source.should start_with 'function onClick3'
            @browser.source.split("\n")[entry.trace[0].line].should include 'log_execution_flow_sink(1)'
            entry.trace[0].function.arguments.should be_empty

            entry.trace[1].function.name.should == 'onClick'
            entry.trace[1].function.source.should start_with 'function onClick'
            @browser.source.split("\n")[entry.trace[1].line].should include 'onClick3()'
            entry.trace[1].function.arguments.should == %w(some-arg arguments-arg here-arg)

            entry.trace[2].function.name.should == 'onsubmit'
            entry.trace[2].function.source.should start_with 'function onsubmit'
            @browser.source.split("\n")[entry.trace[2].line].should include 'onClick('

            event = entry.trace[2].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            event['target'].should == form
            event['srcElement'].should == form
            event['type'].should == 'submit'
        end

        it 'returns data-flow sink data' do
            @browser.javascript.taint = 'taint'
            @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_data_flow_sink_stub( @browser.javascript.taint, function: 'blah' )}"
            @browser.explore_and_flush

            pages = @browser.page_snapshots_with_sinks
            doms  = pages.map(&:dom)

            doms.size.should == 2

            doms[0].data_flow_sinks.size.should == 2

            entry = doms[0].data_flow_sinks[0]
            entry.function.should == 'blah'
            entry.trace.size.should == 3

            entry.trace[0].function.name.should == 'onClick'
            entry.trace[0].function.source.should start_with 'function onClick'
            @browser.source.split("\n")[entry.trace[0].line].should include 'log_data_flow_sink('
            entry.trace[0].function.arguments.should == [1, 2]

            entry.trace[1].function.name.should == 'onClick2'
            entry.trace[1].function.source.should start_with 'function onClick2'
            @browser.source.split("\n")[entry.trace[1].line].should include 'onClick'
            entry.trace[1].function.arguments.should == %w(blah1 blah2 blah3)

            entry.trace[2].function.name.should == 'onmouseover'
            entry.trace[2].function.source.should start_with 'function onmouseover'

            event = entry.trace[2].function.arguments.first

            link = "<a href=\"#\" onmouseover=\"onClick2('blah1', 'blah2', 'blah3');\">Blah</a>"
            event['target'].should == link
            event['srcElement'].should == link
            event['type'].should == 'mouseover'

            entry = doms[0].data_flow_sinks[1]
            entry.function.should == 'blah'
            entry.trace.size.should == 4

            entry.trace[0].function.name.should == 'onClick3'
            entry.trace[0].function.source.should start_with 'function onClick3'
            @browser.source.split("\n")[entry.trace[0].line].should include 'log_data_flow_sink('
            entry.trace[0].function.arguments.should be_empty

            entry.trace[1].function.name.should == 'onClick'
            entry.trace[1].function.source.should start_with 'function onClick'
            @browser.source.split("\n")[entry.trace[1].line].should include 'onClick3'
            entry.trace[1].function.arguments.should == [1, 2]

            entry.trace[2].function.name.should == 'onClick2'
            entry.trace[2].function.source.should start_with 'function onClick2'
            @browser.source.split("\n")[entry.trace[2].line].should include 'onClick'
            entry.trace[2].function.arguments.should == %w(blah1 blah2 blah3)

            entry.trace[3].function.name.should == 'onmouseover'
            entry.trace[3].function.source.should start_with 'function onmouseover'

            event = entry.trace[3].function.arguments.first

            link = "<a href=\"#\" onmouseover=\"onClick2('blah1', 'blah2', 'blah3');\">Blah</a>"
            event['target'].should == link
            event['srcElement'].should == link
            event['type'].should == 'mouseover'

            doms[1].data_flow_sinks.size.should == 2

            entry = doms[1].data_flow_sinks[0]
            entry.function.should == 'blah'
            entry.trace.size.should == 2

            entry.trace[0].function.name.should == 'onClick'
            entry.trace[0].function.source.should start_with 'function onClick'
            @browser.source.split("\n")[entry.trace[0].line].should include 'log_data_flow_sink('
            entry.trace[0].function.arguments.should == %w(some-arg arguments-arg here-arg)

            entry.trace[1].function.name.should == 'onsubmit'
            entry.trace[1].function.source.should start_with 'function onsubmit'
            @browser.source.split("\n")[entry.trace[1].line].should include 'onClick'

            event = entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            event['target'].should == form
            event['srcElement'].should == form
            event['type'].should == 'submit'

            entry = doms[1].data_flow_sinks[1]
            entry.function.should == 'blah'
            entry.trace.size.should == 3

            entry.trace[0].function.name.should == 'onClick3'
            entry.trace[0].function.source.should start_with 'function onClick3'
            @browser.source.split("\n")[entry.trace[0].line].should include 'log_data_flow_sink('
            entry.trace[0].function.arguments.should be_empty

            entry.trace[1].function.name.should == 'onClick'
            entry.trace[1].function.source.should start_with 'function onClick'
            @browser.source.split("\n")[entry.trace[1].line].should include 'onClick3()'
            entry.trace[1].function.arguments.should == %w(some-arg arguments-arg here-arg)

            entry.trace[2].function.name.should == 'onsubmit'
            entry.trace[2].function.source.should start_with 'function onsubmit'
            @browser.source.split("\n")[entry.trace[2].line].should include 'onClick('

            event = entry.trace[2].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            event['target'].should == form
            event['srcElement'].should == form
            event['type'].should == 'submit'
        end

        describe 'when store_pages: false' do
            it 'does not store pages' do
                @browser.shutdown
                @browser = @browser.class.new( store_pages: false )

                @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_execution_flow_sink_stub(1)}"
                @browser.explore_and_flush
                @browser.page_snapshots_with_sinks.should be_empty
            end
        end
    end

    describe '#response' do
        it "returns the #{Arachni::HTTP::Response} for the loaded page" do
            @browser.load @url

            browser_response = @browser.response
            browser_request  = browser_response.request
            raw_response     = Arachni::HTTP::Client.get( @url, mode: :sync )
            raw_request      = raw_response.request

            browser_response.url.should == raw_response.url

            [:url, :method].each do |attribute|
                browser_request.send(attribute).should == raw_request.send(attribute)
            end
        end

        context "when the response takes more than #{Arachni::OptionGroups::HTTP}#request_timeout" do
            it 'returns nil'
        end

        context 'when the resource is out-of-scope' do
            it 'returns nil' do
                Arachni::Options.url = @url
                @browser.load 'http://google.com/'
                @browser.response.should be_nil
            end
        end
    end

    describe '#to_page' do
        it "converts the working window to an #{Arachni::Page}" do
            ua = Arachni::Options.http.user_agent

            @browser.load( @url )
            page = @browser.to_page

            page.should be_kind_of Arachni::Page

            ua.should_not be_empty
            page.response.body.should_not include( ua )
            page.body.should include( ua )
        end

        it "assigns the proper #{Arachni::Page::DOM}#digest" do
            @browser.load( @url )
            @browser.to_page.dom.instance_variable_get(:@digest).should ==
                '<HTML><HEAD><SCRIPT src=http://javascript.browser.arachni/' <<
                    'taint_tracer.js><SCRIPT><SCRIPT src=http://javascript.' <<
                    'browser.arachni/dom_monitor.js><SCRIPT><TITLE><BODY><' <<
                    'DIV><SCRIPT type=text/javascript><SCRIPT type=text/javascript>'
        end

        it "assigns the proper #{Arachni::Page::DOM}#transitions" do
            @browser.load( @url )
            page = @browser.to_page

            page.dom.transitions.should == transitions_from_array([
                { page: :load },
                { @url => :request }
            ])
        end

        it "assigns the proper #{Arachni::Page::DOM}#skip_states" do
            @browser.load( @url )
            pages = @browser.load( @url + '/explore' ).trigger_events.
                page_snapshots

            page = pages.last
            page.dom.skip_states.should be_subset @browser.skip_states
        end

        it "assigns the proper #{Arachni::Page::DOM} sink data" do
            @browser.load "#{web_server_url_for( :taint_tracer )}/debug" <<
                              "?input=#{@browser.javascript.log_execution_flow_sink_stub(1)}"
            @browser.watir.form.submit

            page = @browser.to_page
            sink_data = page.dom.execution_flow_sinks

            first_entry = sink_data.first
            sink_data.should == [first_entry]

            first_entry.data.should == [1]
            first_entry.trace.size.should == 2

            first_entry.trace[0].function.name.should == 'onClick'
            first_entry.trace[0].function.source.should start_with 'function onClick'
            @browser.source.split("\n")[first_entry.trace[0].line].should include 'log_execution_flow_sink(1)'
            first_entry.trace[0].function.arguments.should == %w(some-arg arguments-arg here-arg)

            first_entry.trace[1].function.name.should == 'onsubmit'
            first_entry.trace[1].function.source.should start_with 'function onsubmit'
            @browser.source.split("\n")[first_entry.trace[1].line].should include 'onClick('
            first_entry.trace[1].function.arguments.size.should == 1

            event = first_entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            event['target'].should == form
            event['srcElement'].should == form
            event['type'].should == 'submit'
        end

        context "when the page has #{Arachni::Element::Form::DOM} elements" do
            context "and #{Arachni::OptionGroups::Audit}#forms is" do
                context true do
                    before do
                        Arachni::Options.audit.elements :form
                    end

                    context 'a JavaScript action' do
                        it 'does not set #skip_dom' do
                            @browser.load "#{@url}/each_element_with_events/form/action/javascript"
                            @browser.to_page.forms.first.skip_dom.should be_nil
                        end
                    end

                    context 'with DOM events' do
                        it 'does not set #skip_dom' do
                            @browser.load "#{@url}/fire_event/form/onsubmit"
                            @browser.to_page.forms.first.skip_dom.should be_nil
                        end
                    end

                    context 'without DOM events' do
                        it 'sets #skip_dom to true' do
                            @browser.load "#{@url}/each_element_with_events/form/action/regular"
                            @browser.to_page.forms.first.skip_dom.should be_true
                        end
                    end
                end

                context false do
                    before do
                        Arachni::Options.audit.skip_elements :form
                    end

                    it 'does not set #skip_dom' do
                        @browser.load "#{@url}/each_element_with_events/form/action/regular"
                        @browser.to_page.forms.first.skip_dom.should be_nil
                    end
                end
            end
        end

        context 'when the resource is out-of-scope' do
            it 'returns an empty page' do
                Arachni::Options.url = @url
                subject.load 'http://google.com/'
                page = subject.to_page

                page.code.should == 0
                page.url.should  == subject.url
                page.body.should be_empty
                page.dom.url.should == subject.watir.url
            end
        end
    end

    describe '#fire_event' do
        let(:url) { "#{@url}/trigger_events" }
        before(:each) do
            @browser.load url
        end

        it 'fires the given event' do
            @browser.fire_event @browser.watir.div( id: 'my-div' ), :click
            pages_should_have_form_with_input [@browser.to_page], 'by-ajax'
        end

        it 'accepts events without the "on" prefix' do
            pages_should_not_have_form_with_input [@browser.to_page], 'by-ajax'

            @browser.fire_event @browser.watir.div( id: 'my-div' ), :onclick
            pages_should_have_form_with_input [@browser.to_page], 'by-ajax'

            @browser.fire_event @browser.watir.div( id: 'my-div' ), :click
            pages_should_have_form_with_input [@browser.to_page], 'by-ajax'
        end

        it 'returns a playable transition' do
            transition = @browser.fire_event @browser.watir.div( id: 'my-div' ), :click
            pages_should_have_form_with_input [@browser.to_page], 'by-ajax'

            @browser.load( url ).start_capture
            pages_should_not_have_form_with_input [@browser.to_page], 'by-ajax'

            transition.play @browser
            pages_should_have_form_with_input [@browser.to_page], 'by-ajax'
        end

        context 'when the element is not visible' do
            it 'returns nil' do
                element = @browser.watir.div( id: 'my-div' )

                element.stub(:visible?) { false }

                @browser.fire_event( element, :click ).should be_nil
            end
        end

        context "when the element is an #{described_class::ElementLocator}" do
            context 'and could not be located' do
                it 'returns nil' do
                    element = described_class::ElementLocator.new(
                        tag_name:   'body',
                        attributes: { 'id' => 'blahblah' }
                    )

                    element.stub(:locate){ raise Selenium::WebDriver::Error::WebDriverError }
                    @browser.fire_event( element, :click ).should be_nil

                    element.stub(:locate){ raise Watir::Exception::Error }
                    @browser.fire_event( element, :click ).should be_nil
                end
            end
        end

        context 'when the element never appears' do
            it 'returns nil' do
                element = @browser.watir.div( id: 'my-div' )

                element.stub(:exists?) { false }

                @browser.fire_event( element, :click ).should be_nil
            end
        end

        context 'when the trigger fails with' do
            let(:element) { @browser.watir.div( id: 'my-div' ) }

            context Selenium::WebDriver::Error::WebDriverError do
                it 'returns nil' do
                    element.stub(:fire_event){ raise Selenium::WebDriver::Error::WebDriverError }
                    @browser.fire_event( element, :click ).should be_nil
                end
            end

            context Watir::Exception::Error do
                it 'returns nil' do
                    element.stub(:fire_event){ raise Watir::Exception::Error }
                    @browser.fire_event( element, :click ).should be_nil
                end
            end
        end

        context 'form' do
            context :submit do
                let(:url) { "#{@url}/fire_event/form/onsubmit" }

                context 'when option' do
                    describe :inputs do
                        context 'is given' do
                            let(:inputs) do
                                {
                                    name:  "The Dude",
                                    email: 'the.dude@abides.com'
                                }
                            end

                            before(:each) do
                                @browser.fire_event @browser.watir.form, :submit, inputs: inputs
                            end

                            it 'fills in its inputs with the given values' do
                                @browser.watir.div( id: 'container-name' ).text.should ==
                                    inputs[:name]
                                @browser.watir.div( id: 'container-email' ).text.should ==
                                    inputs[:email]
                            end

                            it 'returns a playable transition' do
                                @browser.load url

                                transition = @browser.fire_event @browser.watir.form, :submit, inputs: inputs

                                @browser.load url

                                @browser.watir.div( id: 'container-name' ).text.should be_empty
                                @browser.watir.div( id: 'container-email' ).text.should be_empty

                                transition.play @browser

                                @browser.watir.div( id: 'container-name' ).text.should ==
                                    inputs[:name]
                                @browser.watir.div( id: 'container-email' ).text.should ==
                                    inputs[:email]
                            end

                            context 'when the inputs contains non-UTF8 data' do
                                context 'is given' do
                                    let(:inputs) do
                                        {
                                            name:  "The Dude \xC7",
                                            email: "the.dude@abides.com \xC7"
                                        }
                                    end
                                end

                                it 'recodes them' do
                                    @browser.watir.div( id: 'container-name' ).text.should ==
                                        inputs[:name].recode
                                    @browser.watir.div( id: 'container-email' ).text.should ==
                                        inputs[:email].recode
                                end
                            end

                            context 'when one of those inputs is a' do
                                context 'select' do
                                    let(:url) { "#{@url}/fire_event/form/select" }

                                    it 'selects it' do
                                        @browser.watir.div( id: 'container-name' ).text.should ==
                                            inputs[:name]
                                        @browser.watir.div( id: 'container-email' ).text.should ==
                                            inputs[:email]
                                    end
                                end
                            end

                            context 'but has missing values' do
                                let(:inputs) do
                                    { name:  'The Dude' }
                                end

                                it 'leaves those empty' do
                                    @browser.watir.div( id: 'container-name' ).text.should ==
                                        inputs[:name]
                                    @browser.watir.div( id: 'container-email' ).text.should be_empty
                                end

                                it 'returns a playable transition' do
                                    @browser.load url
                                    transition = @browser.fire_event @browser.watir.form, :submit, inputs: inputs

                                    @browser.load url

                                    @browser.watir.div( id: 'container-name' ).text.should be_empty
                                    @browser.watir.div( id: 'container-email' ).text.should be_empty

                                    transition.play @browser

                                    @browser.watir.div( id: 'container-name' ).text.should ==
                                        inputs[:name]
                                    @browser.watir.div( id: 'container-email' ).text.should be_empty
                                end
                            end

                            context 'and is empty' do
                                let(:inputs) do
                                    {}
                                end

                                it 'fills in empty values' do
                                    @browser.watir.div( id: 'container-name' ).text.should be_empty
                                    @browser.watir.div( id: 'container-email' ).text.should be_empty
                                end

                                it 'returns a playable transition' do
                                    @browser.load url
                                    transition = @browser.fire_event @browser.watir.form, :submit, inputs: inputs

                                    @browser.load url

                                    @browser.watir.div( id: 'container-name' ).text.should be_empty
                                    @browser.watir.div( id: 'container-email' ).text.should be_empty

                                    transition.play @browser

                                    @browser.watir.div( id: 'container-name' ).text.should be_empty
                                    @browser.watir.div( id: 'container-email' ).text.should be_empty
                                end
                            end

                            context 'and has disabled inputs' do
                                let(:url) { "#{@url}/fire_event/form/disabled_inputs" }

                                it 'is skips those inputs' do
                                    @browser.watir.div( id: 'container-name' ).text.should ==
                                        inputs[:name]
                                    @browser.watir.div( id: 'container-email' ).text.should be_empty
                                end
                            end
                        end

                        context 'is not given' do
                            it 'fills in its inputs with sample values' do
                                @browser.load url
                                @browser.fire_event @browser.watir.form, :submit

                                @browser.watir.div( id: 'container-name' ).text.should ==
                                    Arachni::Options.input.value_for_name( 'name' )
                                @browser.watir.div( id: 'container-email' ).text.should ==
                                    Arachni::Options.input.value_for_name( 'email' )
                            end

                            it 'returns a playable transition' do
                                @browser.load url
                                transition = @browser.fire_event @browser.watir.form, :submit

                                @browser.load url

                                @browser.watir.div( id: 'container-name' ).text.should be_empty
                                @browser.watir.div( id: 'container-email' ).text.should be_empty

                                transition.play @browser

                                @browser.watir.div( id: 'container-name' ).text.should ==
                                    Arachni::Options.input.value_for_name( 'name' )
                                @browser.watir.div( id: 'container-email' ).text.should ==
                                    Arachni::Options.input.value_for_name( 'email' )
                            end

                            context 'and has disabled inputs' do
                                let(:url) { "#{@url}/fire_event/form/disabled_inputs" }

                                it 'is skips those inputs' do
                                    @browser.fire_event @browser.watir.form, :submit

                                    @browser.watir.div( id: 'container-name' ).text.should ==
                                        Arachni::Options.input.value_for_name( 'name' )
                                    @browser.watir.div( id: 'container-email' ).text.should be_empty
                                end
                            end
                        end
                    end
                end
            end

            context 'image button' do
                context :click do
                    before( :each ) { @browser.start_capture }
                    let(:url) { "#{@url}fire_event/form/image-input" }

                    it 'submits the form with x, y coordinates' do
                        @browser.load( url )
                        @browser.fire_event @browser.watir.input( type: 'image'), :click

                        pages_should_have_form_with_input @browser.captured_pages, 'myImageButton.x'
                        pages_should_have_form_with_input @browser.captured_pages, 'myImageButton.y'
                    end

                    it 'returns a playable transition' do
                        @browser.load( url )
                        transition = @browser.fire_event @browser.watir.input( type: 'image'), :click

                        captured_pages = @browser.flush_pages
                        pages_should_have_form_with_input captured_pages, 'myImageButton.x'
                        pages_should_have_form_with_input captured_pages, 'myImageButton.y'
                        @browser.shutdown

                        @browser = described_class.new.start_capture
                        @browser.load( url )
                        @browser.flush_pages.size.should == 1

                        transition.play @browser
                        captured_pages = @browser.flush_pages
                        pages_should_have_form_with_input captured_pages, 'myImageButton.x'
                        pages_should_have_form_with_input captured_pages, 'myImageButton.y'
                    end
                end
            end
        end

        context 'input' do
            described_class::Javascript::EVENTS_PER_ELEMENT[:input].each do |event|
                calculate_expectation = proc do |string|
                    [:onkeypress, :onkeydown].include?( event ) ?
                        string[0...-1] : string
                end

                context event do
                    let( :url ) { "#{@url}/fire_event/input/#{event}" }

                    context 'when option' do
                        describe :inputs do
                            context 'is given' do
                                let(:value) do
                                    'The Dude'
                                end

                                before(:each) do
                                    @browser.fire_event @browser.watir.input, event, value: value
                                end

                                it 'fills in its inputs with the given values' do
                                    @browser.watir.div( id: 'container' ).text.should ==
                                        calculate_expectation.call( value )
                                end

                                it 'returns a playable transition' do
                                    @browser.load url
                                    transition = @browser.fire_event @browser.watir.input, event, value: value

                                    @browser.load url
                                    @browser.watir.div( id: 'container' ).text.should be_empty

                                    transition.play @browser
                                    @browser.watir.div( id: 'container' ).text.should ==
                                        calculate_expectation.call( value )
                                end

                                context 'and is empty' do
                                    let(:value) do
                                        ''
                                    end

                                    it 'fills in empty values' do
                                        @browser.watir.div( id: 'container' ).text.should be_empty
                                    end

                                    it 'returns a playable transition' do
                                        @browser.load url
                                        transition = @browser.fire_event @browser.watir.input, event, value: value

                                        @browser.load url
                                        @browser.watir.div( id: 'container' ).text.should be_empty

                                        transition.play @browser
                                        @browser.watir.div( id: 'container' ).text.should be_empty
                                    end
                                end
                            end

                            context 'is not given' do
                                it 'fills in a sample value' do
                                    @browser.fire_event @browser.watir.input, event

                                    @browser.watir.div( id: 'container' ).text.should ==
                                        calculate_expectation.call( Arachni::Options.input.value_for_name( 'name' ) )
                                end

                                it 'returns a playable transition' do
                                    @browser.load url
                                    transition = @browser.fire_event @browser.watir.input, event

                                    @browser.load url
                                    @browser.watir.div( id: 'container' ).text.should be_empty

                                    transition.play @browser
                                    @browser.watir.div( id: 'container' ).text.should ==
                                        calculate_expectation.call( Arachni::Options.input.value_for_name( 'name' ) )
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    describe '#each_element_with_events' do
        before :each do
            @browser.load url
        end
        let(:elements_with_events) do
            elements_with_events = []
            @browser.each_element_with_events do |*info|
                elements_with_events << info
            end
            elements_with_events
        end

        let(:url) { @url + '/trigger_events' }
        it 'passes each element and event info to the block' do
            elements_with_events.should == [
                [
                    described_class::ElementLocator.new(
                        tag_name:   'body',
                        attributes: { 'onmouseover' => 'makePOST();' }
                    ),
                    [[:onmouseover, 'makePOST();']]
                ],
                [
                    described_class::ElementLocator.new(
                        tag_name:   'div',
                        attributes: { 'id' => 'my-div', 'onclick' => 'addForm();' }
                    ),
                    [[:onclick, 'addForm();']]
                ]
            ]
        end

        context :a do
            context 'and the href is not empty' do
                context 'and it starts with javascript:' do
                    let(:url) { @url + '/each_element_with_events/a/href/javascript' }

                    it 'includes the :click event' do
                        elements_with_events.should == [
                            [
                                described_class::ElementLocator.new(
                                    tag_name:   'a',
                                    attributes: { 'href' => 'javascript:doStuff()' }
                                ),
                                [[:click, 'javascript:doStuff()']]
                            ]
                        ]
                    end
                end

                context 'and it does not start with javascript:' do
                    let(:url) { @url + '/each_element_with_events/a/href/regular' }

                    it 'is ignored' do
                        elements_with_events.should be_empty
                    end
                end

                context 'and is out of scope' do
                    let(:url) { @url + '/each_element_with_events/a/href/out-of-scope' }

                    it 'is ignored' do
                        elements_with_events.should be_empty
                    end
                end
            end
        end

        context :form do
            context :input do
                context 'of type "image"' do
                    let(:url) { @url + '/each_element_with_events/form/input/image' }

                    it 'includes the :click event' do
                        elements_with_events.should == [
                            [
                                described_class::ElementLocator.new(
                                    tag_name:   'input',
                                    attributes: {
                                        'type' => 'image',
                                        'name' => 'myImageButton',
                                        'src'  => '/__sinatra__/404.png'
                                    }
                                ),
                                [[:click, 'image']]
                            ]
                        ]
                    end
                end
            end

            context 'and the action is not empty' do
                context 'and it starts with javascript:' do
                    let(:url) { @url + '/each_element_with_events/form/action/javascript' }

                    it 'includes the :submit event' do
                        elements_with_events.should == [
                            [
                                described_class::ElementLocator.new(
                                    tag_name:   'form',
                                    attributes: {
                                        'action' => 'javascript:doStuff()'
                                    }
                                ),
                                [[:submit, 'javascript:doStuff()']]
                            ]
                        ]
                    end
                end

                context 'and it does not start with javascript:' do
                    let(:url) { @url + '/each_element_with_events/form/action/regular' }

                    it 'is ignored'do
                        elements_with_events.should be_empty
                    end
                end

                context 'and is out of scope' do
                    let(:url) { @url + '/each_element_with_events/form/action/out-of-scope' }

                    it 'is ignored'do
                        elements_with_events.should be_empty
                    end
                end
            end
        end
    end

    describe '#trigger_event' do
        it 'triggers the given event on the given tag and captures snapshots' do
            @browser.load( @url + '/trigger_events' ).start_capture

            locators = []
            @browser.watir.elements.each do |element|
                begin
                    locators << described_class::ElementLocator.from_html( element.opening_tag )
                rescue
                end
            end

            locators.each do |element|
                @browser.javascript.class.events.each do |e|
                    begin
                        @browser.trigger_event @browser.to_page, element, e
                    rescue
                        next
                    end
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
            pages.map(&:dom).map(&:transitions).should == [
                [
                    { :page => :load },
                    { "#{@url}explore" => :request }
                ],
                [
                    { :page => :load },
                    { "#{@url}explore" => :request },
                    {
                        {
                            tag_name: 'div',
                            attributes: {
                                'id'      => 'my-div',
                                'onclick' => 'addForm();'
                            }
                        } => :click
                    },
                    { "#{@url}get-ajax?ajax-token=my-token" => :request }
                ],
                [
                    { :page => :load },
                    { "#{@url}explore" => :request },
                    {
                        {
                            tag_name: 'a',
                            attributes: {
                                'href' => 'javascript:inHref();'
                            }
                        } => :click
                    },
                    { "#{@url}href-ajax" => :request },
                ]
            ].map { |transitions| transitions_from_array( transitions ) }
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

        it 'returns a playable transition' do
            transition = @browser.goto( @url )

            @browser.shutdown
            @browser = described_class.new

            transition.play( @browser )
            ua = Arachni::Options.http.user_agent
            ua.should_not be_empty

            @browser.source.should include( ua )
        end

        context 'when the page has JS timeouts' do
            it 'waits for them to complete' do
                time = Time.now
                subject.goto "#{@url}load_delay"
                waited = Time.now - time

                waited.should >= subject.load_delay / 1000.0
            end
        end

        context 'when there are outstanding HTTP requests' do
            it 'waits for them to complete' do
                sleep_time = 5
                time = Time.now

                subject.goto "#{@url}/ajax_sleep?sleep=#{sleep_time}"

                (Time.now - time).should >= sleep_time
            end

            context "when requests takes more than #{Arachni::OptionGroups::HTTP}#request_timeout" do
                it 'returns false' do
                    sleep_time = 5
                    Arachni::Options.http.request_timeout = 1_000

                    Arachni::HTTP::ProxyServer.any_instance.stub(:has_connections?){ true }

                    time = Time.now
                    subject.goto "#{@url}/ajax_sleep?sleep=#{sleep_time}"

                    (Time.now - time).should < sleep_time
                end
            end
        end

        context "#{Arachni::OptionGroups::BrowserCluster}#ignore_images" do
            context true do
                it 'does not load images' do
                    Arachni::Options.browser_cluster.ignore_images = true
                    @browser.shutdown
                    @browser = described_class.new

                    loaded_image = false
                    @browser.on_response do |response|
                        loaded_image ||= (response.parsed_url.resource_extension == 'png')
                    end

                    @browser.load( "#{@url}form-with-image-button" )

                    loaded_image.should be_false
                end
            end

            context false do
                it 'does not load images' do
                    Arachni::Options.browser_cluster.ignore_images = false
                    @browser.shutdown
                    @browser = described_class.new

                    loaded_image = false
                    @browser.on_response do |response|
                        loaded_image ||= (response.parsed_url.resource_extension == 'png')
                    end

                    @browser.load( "#{@url}form-with-image-button" )

                    loaded_image.should be_true
                end
            end
        end

        context "with #{Arachni::OptionGroups::Scope}#exclude_path_patterns" do
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

        context "with #{Arachni::OptionGroups::Scope}#redundant_path_patterns" do
            it 'respects scope restrictions' do
                Arachni::Options.scope.redundant_path_patterns = { 'explore' => 3 }

                @browser.load( @url + '/explore' ).response.code.should == 200

                2.times do
                    @browser.load( @url + '/explore' ).response.code.should == 200
                end

                @browser.load( @url + '/explore' ).response.code.should == 0
            end
        end

        context "with #{Arachni::OptionGroups::Scope}#auto_redundant_paths has bee configured" do
            it 'respects scope restrictions' do
                Arachni::Options.scope.auto_redundant_paths = 3

                @browser.load( @url + '/explore?test=1&test2=2' ).response.code.should == 200

                2.times do
                    @browser.load( @url + '/explore?test=1&test2=2' ).response.code.should == 200
                end

                @browser.load( @url + '/explore?test=1&test2=2' ).response.code.should == 0
            end
        end

        describe :cookies do
            it 'loads the given cookies' do
                cookie = { 'myname' => 'myvalue' }
                @browser.goto @url, cookies: cookie

                @browser.cookies.find { |c| c.name == cookie.keys.first }.inputs.should == cookie
            end

            it 'includes them in the transition' do
                cookie = { 'myname' => 'myvalue' }
                transition = @browser.goto( @url, cookies: cookie )

                transition.options[:cookies].should == cookie
            end

        context 'when auditing existing cookies' do
            it 'preserves the HttpOnly attribute' do
                @browser.goto( @url )
                @browser.cookies.size.should == 1

                cookies = { @browser.cookies.first.name => 'updated' }
                @browser.goto( @url, cookies: cookies )

                @browser.cookies.first.value == 'updated'
                @browser.cookies.first.should be_http_only
            end
        end

        end

        describe :take_snapshot do
            describe true do
                it 'captures a snapshot of the loaded page' do
                    @browser.goto @url, take_snapshot: true
                    pages = @browser.page_snapshots
                    pages.size.should == 1

                    pages.first.dom.transitions.should == transitions_from_array([
                        { page: :load },
                        { @url => :request }
                    ])
                end
            end

            describe false do
                it 'does not capture a snapshot of the loaded page' do
                    @browser.goto @url, take_snapshot:  false
                    @browser.page_snapshots.should be_empty
                end
            end

            describe 'default' do
                it 'captures a snapshot of the loaded page' do
                    @browser.goto @url
                    pages = @browser.page_snapshots
                    pages.size.should == 1

                    pages.first.dom.transitions.should == transitions_from_array([
                        { page: :load },
                        { @url => :request }
                    ])
                end
            end
        end

        describe :update_transitions do
            describe true do
                it 'pushes the page load to the transitions' do
                    t = @browser.goto( @url, update_transitions: true )
                    @browser.to_page.dom.transitions.should include t
                end
            end

            describe false do
                it 'does not push the page load to the transitions' do
                    t = @browser.goto( @url, update_transitions: false )
                    @browser.to_page.dom.transitions.should be_empty
                end
            end

            describe 'default' do
                it 'pushes the page load to the transitions' do
                    t = @browser.goto( @url )
                    @browser.to_page.dom.transitions.should include t
                end
            end
        end

    end

    describe '#load' do
        it 'returns self' do
            @browser.load( @url ).should == @browser
        end

        describe :cookies do
            it 'loads the given cookies' do
                cookie = { 'myname' => 'myvalue' }
                @browser.load @url, cookies: cookie

                @browser.cookies.find { |c| c.name == cookie.keys.first }.inputs.should == cookie
            end
        end

        describe :take_snapshot do
            describe true do
                it 'captures a snapshot of the loaded page' do
                    @browser.load @url, take_snapshot: true
                    pages = @browser.page_snapshots
                    pages.size.should == 1

                    pages.first.dom.transitions.should == transitions_from_array([
                        { page: :load },
                        { @url => :request }
                    ])
                end
            end

            describe false do
                it 'does not capture a snapshot of the loaded page' do
                    @browser.load @url, take_snapshot: false
                    @browser.page_snapshots.should be_empty
                end
            end

            describe 'default' do
                it 'captures a snapshot of the loaded page' do
                    @browser.load @url
                    pages = @browser.page_snapshots
                    pages.size.should == 1

                    pages.first.dom.transitions.should == transitions_from_array([
                        { page: :load },
                        { @url => :request }
                    ])
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

                it 'uses its #cookie_jar' do
                    @browser.cookies.should be_empty

                    page = Arachni::Page.from_data(
                        url:        @url,
                        cookie_jar:  [
                            Arachni::Cookie.new(
                                url:    @url,
                                inputs: {
                                    'my-name' => 'my-value'
                                }
                            )
                        ]
                    )

                    @browser.load( page )
                    @browser.cookies.should == page.cookie_jar
                end

                it 'replays its DOM#transitions' do
                    @browser.load "#{@url}play-transitions"
                    page = @browser.explore_and_flush.last
                    page.body.should include ua

                    @browser.load page
                    @browser.source.should include ua

                    page.dom.transitions.clear
                    @browser.load page
                    @browser.source.should_not include ua
                end

                it 'loads its DOM#skip_states' do
                    @browser.load( @url )
                    pages = @browser.load( @url + '/explore' ).trigger_events.
                        page_snapshots

                    page = pages.last
                    page.dom.skip_states.should be_subset @browser.skip_states

                    token = @browser.generate_token

                    dpage = page.dup
                    dpage.dom.skip_states << token

                    @browser.load dpage
                    @browser.skip_states.should include token
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
        before(:each) { @browser.start_capture }

        it 'parses requests into elements of pages' do
            @browser.load @url + '/with-ajax'

            pages = @browser.captured_pages
            pages.size.should == 2

            page = pages.first
            page.forms.find { |form| form.inputs.include? 'ajax-token' }.should be_true
        end

        context 'when an element has already been seen' do
            context 'by the browser' do
                it 'ignores it' do
                    @browser.load @url + '/with-ajax'
                    @browser.captured_pages.size.should == 2
                    @browser.captured_pages.clear

                    @browser.load @url + '/with-ajax'
                    @browser.captured_pages.should be_empty
                end
            end

            context "by the #{Arachni::ElementFilter}" do
                it 'ignores it' do
                    @browser.load @url + '/with-ajax'
                    Arachni::ElementFilter.update_forms @browser.captured_pages.map(&:forms).flatten
                    @browser.shutdown

                    @browser = described_class.new
                    @browser.load @url + '/with-ajax'
                    @browser.captured_pages.should be_empty
                end
            end
        end

        context 'when a GET request is performed' do
            it "is added as an #{Arachni::Element::Form} to the page" do
                @browser.load @url + '/with-ajax'

                pages = @browser.captured_pages
                pages.size.should == 2

                page = pages.first

                form = page.forms.find { |form| form.inputs.include? 'ajax-token' }

                form.url.should == @url + 'with-ajax'
                form.action.should == @url + 'get-ajax'
                form.inputs.should == { 'ajax-token' => 'my-token' }
                form.method.should == :get
            end
        end

        context 'when a POST request is performed' do
            context 'with form data' do
                it "is added as an #{Arachni::Element::Form} to the page" do
                    @browser.load @url + '/with-ajax'

                    pages = @browser.captured_pages
                    pages.size.should == 2

                    form = find_page_with_form_with_input( pages, 'post-name' ).
                        forms.find { |form| form.inputs.include? 'post-name' }

                    form.url.should == @url + 'with-ajax'
                    form.action.should == @url + 'post-ajax'
                    form.inputs.should == { 'post-name' => 'post-value' }
                    form.method.should == :post
                end
            end

            context 'with JSON data' do
                it "is added as an #{Arachni::Element::JSON} to the page" do
                    @browser.load @url + '/with-ajax-json'

                    pages = @browser.captured_pages
                    pages.size.should == 1

                    form = find_page_with_json_with_input( pages, 'post-name' ).
                        jsons.find { |json| json.inputs.include? 'post-name' }

                    form.url.should == @url + 'with-ajax-json'
                    form.action.should == @url + 'post-ajax'
                    form.inputs.should == { 'post-name' => 'post-value' }
                    form.method.should == :post
                end
            end

            context 'with XML data' do
                it "is added as an #{Arachni::Element::XML} to the page" do
                    @browser.load @url + '/with-ajax-xml'

                    pages = @browser.captured_pages
                    pages.size.should == 1

                    form = find_page_with_xml_with_input( pages, 'input > text()' ).
                        xmls.find { |xml| xml.inputs.include? 'input > text()' }

                    form.url.should == @url + 'with-ajax-xml'
                    form.action.should == @url + 'post-ajax'
                    form.inputs.should == { 'input > text()' => 'stuff' }
                    form.method.should == :post
                end
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
            @browser.stop_capture
            @browser.capture?.should be_false
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
            cookie.name.should  == 'This name should be updated; and properly escaped'
            cookie.value.should == 'This value should be updated; and properly escaped'
        end

        it 'preserves the HttpOnly attribute' do
            @browser.load @url
            @browser.cookies.first.should be_http_only
        end

        context 'when no page is available' do
            it 'returns an empty Array' do
                @browser.cookies.should be_empty
            end
        end
    end

    describe '#snapshot_id' do
        before(:each) { Arachni::Options.url = @url }

        let(:empty_snapshot_id_url) { @url + '/snapshot_id/default' }
        let(:empty_snapshot_id) do
            @browser.load( empty_snapshot_id_url ).snapshot_id
        end
        let(:snapshot_id) do
            @browser.load( url ).snapshot_id
        end

        let(:url) { @url + '/trigger_events' }

        it 'returns a DOM digest' do
            snapshot_id.should == @browser.load( url ).snapshot_id
        end

        context :a do
            context 'and the href is not empty' do
                context 'and it starts with javascript:' do
                    let(:url) { @url + '/each_element_with_events/a/href/javascript' }

                    it 'takes it into account' do
                        snapshot_id.should_not == empty_snapshot_id
                    end
                end

                context 'and it does not start with javascript:' do
                    let(:url) { @url + '/each_element_with_events/a/href/regular' }

                    it 'takes it into account' do
                        snapshot_id.should_not == empty_snapshot_id
                    end
                end

                context 'and is out of scope' do
                    let(:url) { @url + '/each_element_with_events/a/href/out-of-scope' }

                    it 'is ignored' do
                        snapshot_id.should == empty_snapshot_id
                    end
                end
            end

            context 'and the href is empty' do
                let(:url) { @url + '/each_element_with_events/a/href/empty' }

                it 'takes it into account' do
                    snapshot_id.should_not == empty_snapshot_id
                end
            end
        end

        context :form do
            let(:empty_snapshot_id_url) { @url + '/snapshot_id/form/default' }

            context :input do
                context 'of type "image"' do
                    let(:url) { @url + '/each_element_with_events/form/input/image' }

                    it 'takes it into account' do
                        snapshot_id.should_not == empty_snapshot_id
                    end
                end
            end

            context 'and the action is not empty' do
                context 'and it starts with javascript:' do
                    let(:url) { @url + '/each_element_with_events/form/action/javascript' }

                    it 'takes it into account' do
                        snapshot_id.should_not == empty_snapshot_id
                    end
                end

                context 'and it does not start with javascript:' do
                    let(:url) { @url + '/each_element_with_events/form/action/regular' }

                    it 'takes it into account' do
                        snapshot_id.should_not == empty_snapshot_id
                    end
                end

                context 'and is out of scope' do
                    let(:url) { @url + '/each_element_with_events/form/action/out-of-scope' }

                    it 'is ignored'do
                        snapshot_id.should == empty_snapshot_id
                    end
                end
            end
        end
    end

end
