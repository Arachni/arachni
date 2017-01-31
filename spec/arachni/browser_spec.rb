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
        @browser.shutdown if @browser
        described_class.asset_domains.clear
        clear_hit_count
    end

    let(:subject) { @browser }
    let(:ua) { described_class::USER_AGENT }

    def transitions_from_array( transitions )
        transitions.map do |t|
            element, event = t.first.to_a

            options = {}
            if element == :page && event == :load
                options.merge!( url: @browser.dom_url, cookies: {} )
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

    def image_hit_count
        Typhoeus::Request.get( "#{@url}/image-hit-count" ).body.to_i
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

    context 'when the browser dies' do
        it 'kills the lifeline too' do
            Arachni::Processes::Manager.kill subject.browser_pid
            expect(Arachni::Processes::Manager.alive?(subject.lifeline_pid)).to be_falsey
        end
    end

    context 'when the lifeline dies' do
        it 'kills the browser too' do
            Arachni::Processes::Manager.kill subject.lifeline_pid
            expect(Arachni::Processes::Manager.alive?(subject.browser_pid)).to be_falsey
        end
    end

    describe '#alive?' do
        context 'when the lifeline is alive' do
            it 'returns true' do
                expect(Arachni::Processes::Manager.alive?(subject.lifeline_pid)).to be_truthy
                expect(subject).to be_alive
            end
        end

        context 'when the browser is dead' do
            it 'returns false' do
                Arachni::Processes::Manager.kill subject.browser_pid

                expect(subject).to_not be_alive
            end
        end

        context 'when the lifeline is dead' do
            it 'returns false' do
                Arachni::Processes::Manager << subject.browser_pid
                Arachni::Processes::Manager.kill subject.lifeline_pid

                expect(subject).to_not be_alive
            end
        end
    end

    describe '.has_executable?' do
        context 'when there is no executable browser' do
            it 'returns false' do
                allow(Selenium::WebDriver::PhantomJS).to receive(:path){ false }
                expect(described_class.has_executable?).to be_falsey
            end
        end

        context 'when there is an executable browser' do
            it 'returns true' do
                allow(Selenium::WebDriver::PhantomJS).to receive(:path){ __FILE__ }
                expect(described_class.has_executable?).to be_truthy
            end
        end
    end

    describe '.executable' do
        it 'returns the path to the browser executable' do
            stub = __FILE__
            allow(Selenium::WebDriver::PhantomJS).to receive(:path){ stub }
            expect(described_class.executable).to eq(stub)
        end
    end

    describe '#initialize' do
        describe ':concurrency' do
            it 'sets the HTTP request concurrency'
        end

        describe ':ignore_scope' do
            context 'true' do
                it 'ignores scope restrictions' do
                    @browser.shutdown

                    @browser = described_class.new( ignore_scope: true )

                    Arachni::Options.scope.exclude_path_patterns << /sleep/

                    subject.load @url + '/ajax_sleep'
                    expect(subject.to_page).to be_truthy
                end
            end

            context 'false' do
                it 'enforces scope restrictions' do
                    @browser.shutdown

                    @browser = described_class.new( ignore_scope: false )

                    Arachni::Options.scope.exclude_path_patterns << /sleep/

                    subject.load @url + '/ajax_sleep'
                    expect(subject.to_page.code).to eq(0)
                end
            end

            context ':default' do
                it 'enforces scope restrictions' do
                    @browser.shutdown

                    @browser = described_class.new( ignore_scope: false )

                    Arachni::Options.scope.exclude_path_patterns << /sleep/

                    subject.load @url + '/ajax_sleep'
                    expect(subject.to_page.code).to eq(0)
                end
            end
        end

        describe ':width' do
            it 'sets the window width' do
                @browser.shutdown

                width = 100
                @browser = described_class.new( width: width )

                subject.load @url

                expect(subject.javascript.run('return window.innerWidth')).to eq(width)
            end

            it 'defaults to 1600' do
                subject.load @url

                expect(subject.javascript.run('return window.innerWidth')).to eq(1600)
            end
        end

        describe ':height' do
            it 'sets the window height' do
                @browser.shutdown

                height = 100
                @browser = described_class.new( height: height )

                subject.load @url

                expect(subject.javascript.run('return window.innerHeight')).to eq(height)
            end

            it 'defaults to 1200' do
                subject.load @url

                expect(subject.javascript.run('return window.innerHeight')).to eq(1200)
            end
        end

        describe ':store_pages' do
            describe 'default' do
                it 'stores snapshot pages' do
                    @browser.shutdown
                    @browser = described_class.new
                    expect(@browser.load( @url + '/explore' ).flush_pages).to be_any
                end

                it 'stores captured pages' do
                    @browser.shutdown
                    @browser = described_class.new
                    @browser.start_capture
                    expect(@browser.load( @url + '/with-ajax' ).flush_pages).to be_any
                end
            end

            describe 'true' do
                it 'stores snapshot pages' do
                    @browser.shutdown
                    @browser = described_class.new( store_pages: true )
                    expect(@browser.load( @url + '/explore' ).trigger_events.flush_pages).to be_any
                end

                it 'stores captured pages' do
                    @browser.shutdown
                    @browser = described_class.new( store_pages: true )
                    @browser.start_capture
                    expect(@browser.load( @url + '/with-ajax' ).flush_pages).to be_any
                end
            end

            describe 'false' do
                it 'stores snapshot pages' do
                    @browser.shutdown
                    @browser = described_class.new( store_pages: false )
                    expect(@browser.load( @url + '/explore' ).trigger_events.flush_pages).to be_empty
                end

                it 'stores captured pages' do
                    @browser.shutdown
                    @browser = described_class.new( store_pages: false )
                    @browser.start_capture
                    expect(@browser.load( @url + '/with-ajax' ).flush_pages).to be_empty
                end
            end
        end

        context 'when browser process spawn fails' do
            it "raises #{described_class::Error::Spawn}" do
                allow_any_instance_of(described_class).to receive(:spawn_phantomjs) { nil }
                expect { described_class.new }.to raise_error described_class::Error::Spawn
            end
        end
    end

    describe '#source_with_line_numbers' do
        it 'prefixes each source code line with a number' do
            subject.load @url

            lines = subject.source.lines.to_a

            expect(lines).to be_any
            subject.source_with_line_numbers.lines.each.with_index do |l, i|
                expect(l).to eq("#{i+1} - #{lines[i]}")
            end
        end
    end

    describe '#load_delay' do
        it 'returns nil' do
            subject.load @url
            expect(subject.load_delay).to be_nil
        end

        context 'when the page has JS timeouts' do
            it 'returns the maximum time the browser should wait for the page based on Timeout' do
                subject.load( "#{@url}load_delay" )
                expect(subject.load_delay).to eq(2000)
            end
        end
    end

    describe '#wait_for_timers' do
        it 'returns' do
            subject.load @url
            expect(subject.wait_for_timers).to be_nil
        end

        context 'when the page has JS timeouts' do
            it 'waits for them to complete' do
                subject.load( "#{@url}load_delay" )
                seconds = subject.load_delay / 1000

                time = Time.now
                subject.wait_for_timers
                expect(Time.now - time).to be > seconds
            end

            it "caps them at #{Arachni::OptionGroups::HTTP}#request_timeout" do
                subject.load( "#{@url}load_delay" )

                Arachni::Options.http.request_timeout = 100

                time = Time.now
                subject.wait_for_timers
                expect(Time.now - time).to be < 0.3
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

                expect(captured).to eq(received)
            end

            context '#store_pages?' do
                context 'true' do
                    subject { @browser.shutdown; @browser = described_class.new( store_pages: true )}

                    it 'stores it in #page_snapshots' do
                        captured = subject.capture_snapshot

                        expect(subject.page_snapshots).to eq(captured)
                    end

                    it 'returns it' do
                        expect(captured.size).to eq(1)
                        expect(captured.first).to eq(subject.to_page)
                    end
                end

                context 'false' do
                    subject { @browser.shutdown; @browser = described_class.new( store_pages: false ) }

                    it 'does not store it' do
                        subject.capture_snapshot

                        expect(subject.page_snapshots).to be_empty
                    end

                    it 'returns an empty array' do
                        expect(captured).to be_empty
                    end
                end
            end
        end

        context 'when a snapshot has already been seen' do
            before :each do
                subject.load( @url + '/with-ajax', take_snapshot: false )
            end

            it 'ignores it' do
                expect(subject.capture_snapshot).to be_any
                expect(subject.capture_snapshot).to be_empty
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

                expect(sinks.size).to eq(1)
            end

            context 'and has already been seen' do
                it 'calls #on_new_page_with_sink callbacks' do
                    sinks = []
                    subject.on_new_page_with_sink do |page|
                        sinks << page.dom.execution_flow_sinks
                    end

                    subject.capture_snapshot
                    subject.capture_snapshot

                    expect(sinks.size).to eq(2)
                end
            end

            context '#store_pages?' do
                context 'true' do
                    subject { @browser.shutdown; @browser = described_class.new( store_pages: true )}

                    it 'stores it in #page_snapshots_with_sinks' do
                        subject.capture_snapshot
                        expect(subject.page_snapshots_with_sinks).to be_any
                    end
                end

                context 'false' do
                    subject { @browser.shutdown; @browser = described_class.new( store_pages: false )}

                    it 'does not store it in #page_snapshots_with_sinks' do
                        subject.capture_snapshot
                        expect(subject.page_snapshots_with_sinks).to be_empty
                    end
                end
            end
        end

        context 'when a transition has been given' do
            before :each do
                subject.load( ajax_url, take_snapshot: false )
            end

            it 'pushes it to the existing transitions' do
                transition = Arachni::Page::DOM::Transition.new(
                    :page, :load
                )
                captured = subject.capture_snapshot( transition )

                expect(captured.first.dom.transitions).to include transition
            end
        end

        context 'when a page has the same transitions but different states' do
            it 'only captures the first state' do
                subject.load( "#{@url}/ever-changing-dom", take_snapshot: false )
                expect(subject.capture_snapshot).to be_any

                subject.load( "#{@url}/ever-changing-dom", take_snapshot: false )
                expect(subject.capture_snapshot).to be_empty
            end
        end

        context 'when there are multiple windows open' do

            it 'captures snapshots from all windows' do
                url = "#{@url}open-new-window"

                subject.load url, take_snapshot: false

                expect(subject.capture_snapshot.map(&:url).sort).to eq(
                    [url, "#{@url}with-ajax"].sort
                )
            end
        end

        context 'when an error occurs' do
            it 'ignores it' do
                allow(subject).to receive(:to_page) { raise }
                expect(subject.capture_snapshot( blah: :stuff )).to be_empty
            end
        end
    end

    describe '#flush_page_snapshots_with_sinks' do
        it 'returns pages with data-flow sink data' do
            @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_data_flow_sink_stub( function: { name: 'blah' } )}"
            @browser.explore_and_flush
            expect(@browser.page_snapshots_with_sinks.map(&:dom).map(&:data_flow_sinks)).to eq(
                @browser.flush_page_snapshots_with_sinks.map(&:dom).map(&:data_flow_sinks)
            )
        end

        it 'returns pages with execution-flow sink data' do
            @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_execution_flow_sink_stub( function: { name: 'blah' } )}"
            @browser.explore_and_flush
            expect(@browser.page_snapshots_with_sinks.map(&:dom).map(&:execution_flow_sinks)).to eq(
                @browser.flush_page_snapshots_with_sinks.map(&:dom).map(&:execution_flow_sinks)
            )
        end

        it 'empties the data-flow sink page buffer' do
            @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_data_flow_sink_stub( function: { name: 'blah' } )}"
            @browser.explore_and_flush
            @browser.flush_page_snapshots_with_sinks.map(&:dom).map(&:data_flow_sinks)
            expect(@browser.page_snapshots_with_sinks).to be_empty
        end

        it 'empties the execution-flow sink page buffer' do
            @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_execution_flow_sink_stub( function: { name: 'blah' } )}"
            @browser.explore_and_flush
            @browser.flush_page_snapshots_with_sinks.map(&:dom).map(&:execution_flow_sinks)
            expect(@browser.page_snapshots_with_sinks).to be_empty
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

            expect(sinks.size).to eq(2)
            expect(sinks).to eq(@browser.page_snapshots_with_sinks.map(&:dom).
                map(&:execution_flow_sinks))
        end

        it 'assigns blocks to handle each page with data-flow sink data' do
            @browser.javascript.taint = 'taint'
            @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_data_flow_sink_stub( @browser.javascript.taint, function: { name: 'blah' } )}"

            sinks = []
            @browser.on_new_page_with_sink do |page|
                sinks << page.dom.data_flow_sinks
            end

            @browser.explore_and_flush

            expect(sinks.size).to eq(2)
            expect(sinks).to eq(@browser.page_snapshots_with_sinks.map(&:dom).
                map(&:data_flow_sinks))
        end
    end

    describe '#on_fire_event' do
        it 'gets called before each event is triggered' do
            @browser.load "#{@url}/trigger_events"

            calls = []
            @browser.on_fire_event do |element, event|
                calls << [element.opening_tag, event]
            end

            @browser.fire_event @browser.selenium.find_element( id: 'my-div' ), :click
            @browser.fire_event @browser.selenium.find_element( id: 'my-div' ), :mouseover

            expect(calls).to eq([
                [ "<div id=\"my-div\" onclick=\"addForm();\">", :click ],
                [ "<div id=\"my-div\" onclick=\"addForm();\">", :mouseover ]
            ])
        end
    end

    describe '#on_new_page' do
        it 'is passed each snapshot' do
            pages = []
            @browser.on_new_page { |page| pages << page }

            expect(@browser.load( @url + '/explore' ).trigger_events.
                page_snapshots).to eq(pages)
        end

        it 'is passed each request capture' do
            pages = []
            @browser.on_new_page { |page| pages << page }
            @browser.start_capture

            # Last page will be the root snapshot so ignore it.
            expect(@browser.load( @url + '/with-ajax' ).captured_pages).to eq(pages[0...2])
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
                expect(response).to be_kind_of Arachni::HTTP::Response
                expect(response.url).to eq(@url)
            end
        end

        context 'when a request is performed by the browser' do
            it 'is passed each response' do
                responses = []
                @browser.on_response { |response| responses << response }

                @browser.goto @url

                response = responses.first
                expect(response).to be_kind_of Arachni::HTTP::Response
                expect(response.url).to eq(@url)
            end
        end
    end

    describe '#explore_and_flush' do
        it 'handles deep DOM/page transitions' do
            url = @url + '/deep-dom'
            pages = @browser.load( url ).explore_and_flush

            pages_should_have_form_with_input pages, 'by-ajax'

            expect(pages.map(&:dom).map(&:transitions)).to eq([
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
                                'href'        => '#'
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
                                'href'        => '#'
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
            ].map { |transitions| transitions_from_array( transitions ) })
        end

        context 'with a depth argument' do
            it 'does not go past the given DOM depth' do
                pages = @browser.load( @url + '/deep-dom' ).explore_and_flush(2)

                expect(pages.map(&:dom).map(&:transitions)).to eq([
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
                                    'href'        => '#'
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
                                    'href'        => 'javascript:level3();'
                                }
                            } => :click
                        },
                        { "#{@url}level4" => :request }
                    ]
                ].map { |transitions| transitions_from_array( transitions ) })
            end
        end
    end

    describe '#page_snapshots_with_sinks' do
        it 'returns execution-flow sink data' do
            @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_execution_flow_sink_stub(1)}"
            @browser.explore_and_flush

            pages = @browser.page_snapshots_with_sinks
            doms  = pages.map(&:dom)

            expect(doms.size).to eq(2)

            expect(doms[0].transitions).to eq(transitions_from_array([
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
            ]))

            expect(doms[0].execution_flow_sinks.size).to eq(2)

            entry = doms[0].execution_flow_sinks[0]
            expect(entry.data).to eq([1])

            expect(entry.trace[0].function.name).to eq('onClick')
            expect(entry.trace[0].function.source).to start_with 'function onClick'
            expect(@browser.source.split("\n")[entry.trace[0].line - 1]).to include 'log_execution_flow_sink(1)'
            expect(entry.trace[0].function.arguments).to eq([1, 2])

            expect(entry.trace[1].function.name).to eq('onClick2')
            expect(entry.trace[1].function.source).to start_with 'function onClick2'
            expect(@browser.source.split("\n")[entry.trace[1].line - 1]).to include 'onClick'
            expect(entry.trace[1].function.arguments).to eq(%w(blah1 blah2 blah3))

            expect(entry.trace[2].function.name).to eq('onmouseover')
            expect(entry.trace[2].function.source).to start_with 'function onmouseover'

            event = entry.trace[2].function.arguments.first

            link = "<a href=\"#\" onmouseover=\"onClick2('blah1', 'blah2', 'blah3');\">Blah</a>"
            expect(event['target']).to eq(link)
            expect(event['srcElement']).to eq(link)
            expect(event['type']).to eq('mouseover')

            entry = doms[0].execution_flow_sinks[1]
            expect(entry.data).to eq([1])

            expect(entry.trace[0].function.name).to eq('onClick3')
            expect(entry.trace[0].function.source).to start_with 'function onClick3'
            expect(@browser.source.split("\n")[entry.trace[0].line - 1]).to include 'log_execution_flow_sink(1)'
            expect(entry.trace[0].function.arguments).to be_empty

            expect(entry.trace[1].function.name).to eq('onClick')
            expect(entry.trace[1].function.source).to start_with 'function onClick'
            expect(@browser.source.split("\n")[entry.trace[1].line - 1]).to include 'onClick3'
            expect(entry.trace[1].function.arguments).to eq([1, 2])

            expect(entry.trace[2].function.name).to eq('onClick2')
            expect(entry.trace[2].function.source).to start_with 'function onClick2'
            expect(@browser.source.split("\n")[entry.trace[2].line - 1]).to include 'onClick'
            expect(entry.trace[2].function.arguments).to eq(%w(blah1 blah2 blah3))

            expect(entry.trace[3].function.name).to eq('onmouseover')
            expect(entry.trace[3].function.source).to start_with 'function onmouseover'

            event = entry.trace[3].function.arguments.first

            link = "<a href=\"#\" onmouseover=\"onClick2('blah1', 'blah2', 'blah3');\">Blah</a>"
            expect(event['target']).to eq(link)
            expect(event['srcElement']).to eq(link)
            expect(event['type']).to eq('mouseover')

            expect(doms[1].transitions).to eq(transitions_from_array([
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
            ]))

            expect(doms[1].execution_flow_sinks.size).to eq(2)

            entry = doms[1].execution_flow_sinks[0]
            expect(entry.data).to eq([1])

            expect(entry.trace[0].function.name).to eq('onClick')
            expect(entry.trace[0].function.source).to start_with 'function onClick'
            expect(@browser.source.split("\n")[entry.trace[0].line - 1]).to include 'log_execution_flow_sink(1)'
            expect(entry.trace[0].function.arguments).to eq(%w(some-arg arguments-arg here-arg))

            expect(entry.trace[1].function.name).to eq('onsubmit')
            expect(entry.trace[1].function.source).to start_with 'function onsubmit'
            expect(@browser.source.split("\n")[entry.trace[1].line - 1]).to include 'onClick'

            event = entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            expect(event['target']).to eq(form)
            expect(event['srcElement']).to eq(form)
            expect(event['type']).to eq('submit')

            entry = doms[1].execution_flow_sinks[1]
            expect(entry.data).to eq([1])

            expect(entry.trace[0].function.name).to eq('onClick3')
            expect(entry.trace[0].function.source).to start_with 'function onClick3'
            expect(@browser.source.split("\n")[entry.trace[0].line - 1]).to include 'log_execution_flow_sink(1)'
            expect(entry.trace[0].function.arguments).to be_empty

            expect(entry.trace[1].function.name).to eq('onClick')
            expect(entry.trace[1].function.source).to start_with 'function onClick'
            expect(@browser.source.split("\n")[entry.trace[1].line - 1]).to include 'onClick3()'
            expect(entry.trace[1].function.arguments).to eq(%w(some-arg arguments-arg here-arg))

            expect(entry.trace[2].function.name).to eq('onsubmit')
            expect(entry.trace[2].function.source).to start_with 'function onsubmit'
            expect(@browser.source.split("\n")[entry.trace[2].line - 1]).to include 'onClick('

            event = entry.trace[2].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            expect(event['target']).to eq(form)
            expect(event['srcElement']).to eq(form)
            expect(event['type']).to eq('submit')
        end

        it 'returns data-flow sink data' do
            @browser.javascript.taint = 'taint'
            @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_data_flow_sink_stub( @browser.javascript.taint, function: 'blah' )}"
            @browser.explore_and_flush

            pages = @browser.page_snapshots_with_sinks
            doms  = pages.map(&:dom)

            expect(doms.size).to eq(2)

            expect(doms[0].data_flow_sinks.size).to eq(2)

            entry = doms[0].data_flow_sinks[0]
            expect(entry.function).to eq('blah')

            expect(entry.trace[0].function.name).to eq('onClick')
            expect(entry.trace[0].function.source).to start_with 'function onClick'
            expect(@browser.source.split("\n")[entry.trace[0].line - 1]).to include 'log_data_flow_sink('
            expect(entry.trace[0].function.arguments).to eq([1, 2])

            expect(entry.trace[1].function.name).to eq('onClick2')
            expect(entry.trace[1].function.source).to start_with 'function onClick2'
            expect(@browser.source.split("\n")[entry.trace[1].line - 1]).to include 'onClick'
            expect(entry.trace[1].function.arguments).to eq(%w(blah1 blah2 blah3))

            expect(entry.trace[2].function.name).to eq('onmouseover')
            expect(entry.trace[2].function.source).to start_with 'function onmouseover'

            event = entry.trace[2].function.arguments.first

            link = "<a href=\"#\" onmouseover=\"onClick2('blah1', 'blah2', 'blah3');\">Blah</a>"
            expect(event['target']).to eq(link)
            expect(event['srcElement']).to eq(link)
            expect(event['type']).to eq('mouseover')

            entry = doms[0].data_flow_sinks[1]
            expect(entry.function).to eq('blah')

            expect(entry.trace[0].function.name).to eq('onClick3')
            expect(entry.trace[0].function.source).to start_with 'function onClick3'
            expect(@browser.source.split("\n")[entry.trace[0].line - 1]).to include 'log_data_flow_sink('
            expect(entry.trace[0].function.arguments).to be_empty

            expect(entry.trace[1].function.name).to eq('onClick')
            expect(entry.trace[1].function.source).to start_with 'function onClick'
            expect(@browser.source.split("\n")[entry.trace[1].line - 1]).to include 'onClick3'
            expect(entry.trace[1].function.arguments).to eq([1, 2])

            expect(entry.trace[2].function.name).to eq('onClick2')
            expect(entry.trace[2].function.source).to start_with 'function onClick2'
            expect(@browser.source.split("\n")[entry.trace[2].line - 1]).to include 'onClick'
            expect(entry.trace[2].function.arguments).to eq(%w(blah1 blah2 blah3))

            expect(entry.trace[3].function.name).to eq('onmouseover')
            expect(entry.trace[3].function.source).to start_with 'function onmouseover'

            event = entry.trace[3].function.arguments.first

            link = "<a href=\"#\" onmouseover=\"onClick2('blah1', 'blah2', 'blah3');\">Blah</a>"
            expect(event['target']).to eq(link)
            expect(event['srcElement']).to eq(link)
            expect(event['type']).to eq('mouseover')

            expect(doms[1].data_flow_sinks.size).to eq(2)

            entry = doms[1].data_flow_sinks[0]
            expect(entry.function).to eq('blah')

            expect(entry.trace[0].function.name).to eq('onClick')
            expect(entry.trace[0].function.source).to start_with 'function onClick'
            expect(@browser.source.split("\n")[entry.trace[0].line - 1]).to include 'log_data_flow_sink('
            expect(entry.trace[0].function.arguments).to eq(%w(some-arg arguments-arg here-arg))

            expect(entry.trace[1].function.name).to eq('onsubmit')
            expect(entry.trace[1].function.source).to start_with 'function onsubmit'
            expect(@browser.source.split("\n")[entry.trace[1].line - 1]).to include 'onClick'

            event = entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            expect(event['target']).to eq(form)
            expect(event['srcElement']).to eq(form)
            expect(event['type']).to eq('submit')

            entry = doms[1].data_flow_sinks[1]
            expect(entry.function).to eq('blah')

            expect(entry.trace[0].function.name).to eq('onClick3')
            expect(entry.trace[0].function.source).to start_with 'function onClick3'
            expect(@browser.source.split("\n")[entry.trace[0].line - 1]).to include 'log_data_flow_sink('
            expect(entry.trace[0].function.arguments).to be_empty

            expect(entry.trace[1].function.name).to eq('onClick')
            expect(entry.trace[1].function.source).to start_with 'function onClick'
            expect(@browser.source.split("\n")[entry.trace[1].line - 1]).to include 'onClick3()'
            expect(entry.trace[1].function.arguments).to eq(%w(some-arg arguments-arg here-arg))

            expect(entry.trace[2].function.name).to eq('onsubmit')
            expect(entry.trace[2].function.source).to start_with 'function onsubmit'
            expect(@browser.source.split("\n")[entry.trace[2].line - 1]).to include 'onClick('

            event = entry.trace[2].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            expect(event['target']).to eq(form)
            expect(event['srcElement']).to eq(form)
            expect(event['type']).to eq('submit')
        end

        describe 'when store_pages: false' do
            it 'does not store pages' do
                @browser.shutdown
                @browser = @browser.class.new( store_pages: false )

                @browser.load "#{@url}/lots_of_sinks?input=#{@browser.javascript.log_execution_flow_sink_stub(1)}"
                @browser.explore_and_flush
                expect(@browser.page_snapshots_with_sinks).to be_empty
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

            expect(browser_response.url).to eq(raw_response.url)

            [:url, :method].each do |attribute|
                expect(browser_request.send(attribute)).to eq(raw_request.send(attribute))
            end
        end

        context "when the response takes more than #{Arachni::OptionGroups::HTTP}#request_timeout" do
            it 'returns nil'
        end

        context 'when the resource is out of scope' do
            it 'returns nil' do
                Arachni::Options.url = @url
                @browser.load @url

                subject.javascript.run( 'window.location = "http://google.com/";' )
                sleep 1

                expect(@browser.response).to be_nil
            end
        end
    end

    describe '#state' do
        it 'returns a Page::DOM with enough info to reproduce the current state' do
            @browser.load "#{web_server_url_for( :taint_tracer )}/debug" <<
                "?input=#{@browser.javascript.log_execution_flow_sink_stub(1)}"

            dom   = subject.to_page.dom
            state = subject.state

            expect(state.page).to be_nil
            expect(state.url).to eq dom.url
            expect(state.digest).to eq dom.digest
            expect(state.transitions).to eq dom.transitions
            expect(state.skip_states).to eq dom.skip_states
            expect(state.data_flow_sinks).to be_empty
            expect(state.execution_flow_sinks).to be_empty
        end

        context 'when the URL is about:blank' do
            it 'returns nil' do
                Arachni::Options.url = @url
                subject.load @url

                subject.javascript.run( 'window.location = "about:blank";' )
                sleep 1

                expect(subject.state).to be_nil
            end
        end

        context 'when the resource is out-of-scope' do
            it 'returns an empty page' do
                Arachni::Options.url = @url
                subject.load @url

                subject.javascript.run( 'window.location = "http://google.com/";' )
                sleep 1

                expect(subject.state).to be_nil
            end
        end

    end

    describe '#to_page' do
        it "converts the working window to an #{Arachni::Page}" do
            @browser.load( @url )
            page = @browser.to_page

            expect(page).to be_kind_of Arachni::Page

            expect(ua).not_to be_empty
            expect(page.response.body).not_to include( ua )
            expect(page.body).to include( ua )
        end

        it "assigns the proper #{Arachni::Page::DOM}#digest" do
            @browser.load( @url )
            expect(@browser.to_page.dom.digest).to eq(32000153)

            # expect(@browser.to_page.dom.instance_variable_get(:@digest)).to eq(
            #     '<HTML><HEAD><SCRIPT src=http://' <<
            #     'javascript.browser.arachni/polyfills.js><SCRIPT src=http://' <<
            #     'javascript.browser.arachni/' <<
            #     'taint_tracer.js><SCRIPT src=http://javascript.' <<
            #     'browser.arachni/dom_monitor.js><SCRIPT><TITLE><BODY><' <<
            #     'DIV><SCRIPT type=text/javascript><SCRIPT type=text/javascript>'
            # )
        end

        it "assigns the proper #{Arachni::Page::DOM}#transitions" do
            @browser.load( @url )
            page = @browser.to_page

            expect(page.dom.transitions).to eq(transitions_from_array([
                { page: :load },
                { @url => :request }
            ]))
        end

        it "assigns the proper #{Arachni::Page::DOM}#skip_states" do
            @browser.load( @url )
            pages = @browser.load( @url + '/explore' ).trigger_events.
                page_snapshots

            page = pages.last
            expect(page.dom.skip_states).to be_subset @browser.skip_states
        end

        it "assigns the proper #{Arachni::Page::DOM}#cookies" do
            @browser.load "#{@url}/dom-cookies-names"

            expect(@browser.to_page.dom.cookies).to eq @browser.cookies
        end

        it "assigns the proper #{Arachni::Page::DOM} sink data" do
            @browser.load "#{web_server_url_for( :taint_tracer )}/debug" <<
                              "?input=#{@browser.javascript.log_execution_flow_sink_stub(1)}"
            @browser.watir.form.submit

            page = @browser.to_page
            sink_data = page.dom.execution_flow_sinks

            first_entry = sink_data.first
            expect(sink_data).to eq([first_entry])

            expect(first_entry.data).to eq([1])

            expect(first_entry.trace[0].function.name).to eq('onClick')
            expect(first_entry.trace[0].function.source).to start_with 'function onClick'
            expect(@browser.source.split("\n")[first_entry.trace[0].line - 1]).to include 'log_execution_flow_sink(1)'
            expect(first_entry.trace[0].function.arguments).to eq(%w(some-arg arguments-arg here-arg))

            expect(first_entry.trace[1].function.name).to eq('onsubmit')
            expect(first_entry.trace[1].function.source).to start_with 'function onsubmit'
            expect(@browser.source.split("\n")[first_entry.trace[1].line - 1]).to include 'onClick('
            expect(first_entry.trace[1].function.arguments.size).to eq(1)

            event = first_entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            expect(event['target']).to eq(form)
            expect(event['srcElement']).to eq(form)
            expect(event['type']).to eq('submit')
        end

        context 'when the page has' do
            context "#{Arachni::Element::UIForm} elements" do
                context "and #{Arachni::OptionGroups::Audit}#inputs is" do
                    context 'true' do
                        before do
                            Arachni::Options.audit.elements :ui_forms
                        end

                        context '<input> button' do
                            context 'with DOM events' do
                                it 'parses it' do
                                    @browser.load "#{@url}/to_page/input/button/with_events"

                                    input = @browser.to_page.ui_forms.first

                                    expect(input.action).to eq @browser.url
                                    expect(input.source).to eq '<input type="button" id="insert">'
                                    expect(input.method).to eq :click
                                end
                            end

                            context 'without DOM events' do
                                it 'ignores it' do
                                    @browser.load "#{@url}/to_page/input/button/without_events"
                                    expect(@browser.to_page.ui_forms).to be_empty
                                end
                            end
                        end

                        context '<button>' do
                            context 'with DOM events' do
                                it 'parses it' do
                                    @browser.load "#{@url}/to_page/button/with_events"

                                    input = @browser.to_page.ui_forms.first

                                    expect(input.action).to eq @browser.url
                                    expect(input.source).to eq '<button id="insert">'
                                    expect(input.method).to eq :click
                                end
                            end

                            context 'without DOM events' do
                                it 'ignores it' do
                                    @browser.load "#{@url}to_page/button/without_events"
                                    expect(@browser.to_page.ui_forms).to be_empty
                                end
                            end
                        end
                    end

                    context 'false' do
                        before do
                            Arachni::Options.audit.skip_elements :ui_forms
                        end

                        it 'ignores them' do
                            @browser.load "#{@url}/to_page/button/with_events"
                            expect(@browser.to_page.ui_forms).to be_empty
                        end
                    end
                end
            end

            context "#{Arachni::Element::UIInput} elements" do
                context "and #{Arachni::OptionGroups::Audit}#inputs is" do
                    context 'true' do
                        before do
                            Arachni::Options.audit.elements :ui_inputs
                        end

                        context '<input>' do
                            context 'with DOM events' do
                                it 'parses it' do
                                    @browser.load "#{@url}/to_page/input/with_events"

                                    input = @browser.to_page.ui_inputs.first

                                    expect(input.action).to eq @browser.url
                                    expect(input.source).to eq '<input oninput="handleOnInput();" id="my-input" name="my-input" value="1">'
                                    expect(input.method).to eq :input
                                end
                            end

                            context 'without DOM events' do
                                it 'ignores it' do
                                    @browser.load "#{@url}/to_page/input/without_events"
                                    expect(@browser.to_page.ui_inputs).to be_empty
                                end
                            end
                        end

                        context '<textarea>' do
                            context 'with DOM events' do
                                it 'parses it' do
                                    @browser.load "#{@url}/to_page/textarea/with_events"

                                    input = @browser.to_page.ui_inputs.first

                                    expect(input.action).to eq @browser.url
                                    expect(input.source).to eq '<textarea oninput="handleOnInput();" id="my-input" name="my-input">'
                                    expect(input.method).to eq :input
                                end
                            end

                            context 'without DOM events' do
                                it 'ignores it' do
                                    @browser.load "#{@url}/to_page/textarea/without_events"
                                    expect(@browser.to_page.ui_inputs).to be_empty
                                end
                            end
                        end
                    end

                    context 'false' do
                        before do
                            Arachni::Options.audit.skip_elements :ui_inputs
                        end

                        it 'ignores them' do
                            @browser.load "#{@url}/to_page/input/with_events"
                            expect(@browser.to_page.ui_inputs).to be_empty
                        end
                    end
                end
            end

            context "#{Arachni::Element::Form::DOM} elements" do
                context "and #{Arachni::OptionGroups::Audit}#forms is" do
                    context 'true' do
                        before do
                            Arachni::Options.audit.elements :forms
                        end

                        context 'and JavaScript action' do
                            it 'does not set #skip_dom' do
                                @browser.load "#{@url}/each_element_with_events/form/action/javascript"
                                expect(@browser.to_page.forms.first.skip_dom).to be_nil
                            end
                        end

                        context 'with DOM events' do
                            it 'does not set #skip_dom' do
                                @browser.load "#{@url}/fire_event/form/onsubmit"
                                expect(@browser.to_page.forms.first.skip_dom).to be_nil
                            end
                        end

                        context 'without DOM events' do
                            it 'sets #skip_dom to true' do
                                @browser.load "#{@url}/each_element_with_events/form/action/regular"
                                expect(@browser.to_page.forms.first.skip_dom).to be_truthy
                            end
                        end
                    end

                    context 'false' do
                        before do
                            Arachni::Options.audit.skip_elements :forms
                        end

                        it 'does not set #skip_dom' do
                            @browser.load "#{@url}/each_element_with_events/form/action/regular"
                            expect(@browser.to_page.forms.first.skip_dom).to be_nil
                        end
                    end
                end
            end

            context "#{Arachni::Element::Cookie::DOM} elements" do
                let(:cookies) { @browser.to_page.cookies }

                context "and #{Arachni::OptionGroups::Audit}#cookies is" do
                    context 'true' do
                        before do
                            Arachni::Options.audit.elements :cookies

                            @browser.load "#{@url}/#{page}"
                            @browser.load "#{@url}/#{page}"
                        end

                        context 'with DOM processing of cookie' do
                            context 'names' do
                                let(:page) { 'dom-cookies-names' }

                                it 'does not set #skip_dom' do
                                    expect(cookies.find { |c| c.name == 'js_cookie1' }.skip_dom).to be_nil
                                    expect(cookies.find { |c| c.name == 'js_cookie2' }.skip_dom).to be_nil
                                end

                                it 'does not track HTTP-only cookies' do
                                    expect(cookies.find { |c| c.name == 'http_only_cookie' }.skip_dom).to be true
                                end

                                it 'does not track cookies for other paths' do
                                    expect(cookies.find { |c| c.name == 'other_path' }.skip_dom).to be true
                                end
                            end

                            context 'values' do
                                let(:page) { 'dom-cookies-values' }

                                it 'does not set #skip_dom' do
                                    expect(cookies.find { |c| c.name == 'js_cookie1' }.skip_dom).to be_nil
                                    expect(cookies.find { |c| c.name == 'js_cookie2' }.skip_dom).to be_nil
                                end

                                it 'does not track HTTP-only cookies' do
                                    expect(cookies.find { |c| c.name == 'http_only_cookie' }.skip_dom).to be true
                                end

                                it 'does not track cookies for other paths' do
                                    expect(cookies.find { |c| c.name == 'other_path' }.skip_dom).to be true
                                end
                            end
                        end

                        context 'without DOM processing of cookie' do
                            context 'names' do
                                let(:page) { 'dom-cookies-names' }

                                it 'does not set #skip_dom' do
                                    expect(cookies.find { |c| c.name == 'js_cookie3' }.skip_dom).to be_truthy
                                end
                            end

                            context 'values' do
                                let(:page) { 'dom-cookies-values' }

                                it 'does not set #skip_dom' do
                                    expect(cookies.find { |c| c.name == 'js_cookie3' }.skip_dom).to be_truthy
                                end
                            end
                        end

                        context 'when taints are not exact matches' do
                            context 'names' do
                                let(:page) { 'dom-cookies-names-substring' }

                                it 'does not set #skip_dom' do
                                    expect(cookies.find { |c| c.name == 'js_cookie3' }.skip_dom).to be_truthy
                                end
                            end

                            context 'values' do
                                let(:page) { 'dom-cookies-values-substring' }

                                it 'does not set #skip_dom' do
                                    expect(cookies.find { |c| c.name == 'js_cookie3' }.skip_dom).to be_truthy
                                end
                            end
                        end
                    end

                    context 'false' do
                        before do
                            Arachni::Options.audit.skip_elements :cookies

                            @browser.load "#{@url}/#{page}"
                            @browser.load "#{@url}/#{page}"
                        end

                        let(:page) { 'dom-cookies-names' }

                        it 'does not set #skip_dom' do
                            expect(cookies).to be_any
                            cookies.each do |cookie|
                                expect(cookie.skip_dom).to be_nil
                            end
                        end
                    end
                end
            end
        end

        context 'when the resource is out-of-scope' do
            it 'returns an empty page' do
                Arachni::Options.url = @url
                subject.load @url

                subject.javascript.run( 'window.location = "http://google.com/";' )
                sleep 1

                page = subject.to_page

                expect(page.code).to eq(0)
                expect(page.url).to  eq('http://google.com/')
                expect(page.body).to be_empty
                expect(page.dom.url).to eq('http://google.com/')
            end
        end
    end

    describe '#fire_event' do
        let(:url) { "#{@url}/trigger_events" }
        before(:each) do
            @browser.load url
        end

        it 'fires the given event' do
            @browser.fire_event @browser.selenium.find_element( id: 'my-div' ), :click
            pages_should_have_form_with_input [@browser.to_page], 'by-ajax'
        end

        it 'accepts events without the "on" prefix' do
            pages_should_not_have_form_with_input [@browser.to_page], 'by-ajax'

            @browser.fire_event @browser.selenium.find_element( id: 'my-div' ), :click
            pages_should_have_form_with_input [@browser.to_page], 'by-ajax'

            @browser.fire_event @browser.selenium.find_element( id: 'my-div' ), :click
            pages_should_have_form_with_input [@browser.to_page], 'by-ajax'
        end

        it 'returns a playable transition' do
            transition = @browser.fire_event @browser.selenium.find_element( id: 'my-div' ), :click
            pages_should_have_form_with_input [@browser.to_page], 'by-ajax'

            @browser.load( url ).start_capture
            pages_should_not_have_form_with_input [@browser.to_page], 'by-ajax'

            transition.play @browser
            pages_should_have_form_with_input [@browser.to_page], 'by-ajax'
        end

        context 'when new elements are introduced' do
            let(:url) { "#{@url}/trigger_events/with_new_elements" }

            it 'sets element IDs' do
                expect(@browser.selenium.find_elements( :css, 'a' )).to be_empty

                @browser.fire_event @browser.selenium.find_element( id: 'my-div' ), :click

                expect(@browser.selenium.find_elements( :css, 'a' ).first.opening_tag).to eq '<a href="#blah" data-arachni-id="2073105">'
            end
        end

        context 'when new timers are introduced' do
            let(:url) { "#{@url}/trigger_events/with_new_timers/3000" }

            it 'waits for them' do
                @browser.fire_event @browser.selenium.find_element( id: 'my-div' ), :click
                pages_should_have_form_with_input [@browser.to_page], 'by-ajax'
            end

            context 'when a new timer exceeds Options.http.request_timeout' do
                let(:url) { "#{@url}/trigger_events/with_new_timers/#{Arachni::Options.http.request_timeout + 5000}" }

                it 'waits for Options.http.request_timeout' do
                    t = Time.now

                    @browser.fire_event @browser.selenium.find_element( id: 'my-div' ), :click
                    pages_should_not_have_form_with_input [@browser.to_page], 'by-ajax'

                    expect(Time.now - t).to be <= Arachni::Options.http.request_timeout
                end
            end
        end

        context 'when cookies are set' do
            let(:url) { @url + '/each_element_with_events/set-cookie' }

            it 'sets them globally' do
                expect(Arachni::HTTP::Client.cookies).to be_empty

                @browser.fire_event described_class::ElementLocator.new(
                    tag_name: :button,
                    attributes: {
                        onclick: 'setCookie()'
                    }
                ), :click

                cookie = Arachni::HTTP::Client.cookies.first
                expect(cookie.name).to eq 'cookie_name'
                expect(cookie.value).to eq 'cookie value'
            end
        end

        context 'when the element is not visible' do
            it 'returns nil' do
                @browser.goto "#{url}/invisible-div"
                element = @browser.selenium.find_element( id: 'invisible-div' )
                expect(@browser.fire_event( element, :click )).to be_nil
            end
        end

        context "when the element is an #{described_class::ElementLocator}" do
            context 'and could not be located' do
                it 'returns nil' do
                    element = described_class::ElementLocator.new(
                        tag_name:   'body',
                        attributes: { 'id' => 'blahblah' }
                    )

                    allow(element).to receive(:locate){ raise Selenium::WebDriver::Error::WebDriverError }
                    expect(@browser.fire_event( element, :click )).to be_nil
                end
            end
        end

        context 'when the trigger fails with' do
            let(:element) { @browser.selenium.find_element( id: 'my-div' ) }

            context 'Selenium::WebDriver::Error::WebDriverError' do
                it 'returns nil' do
                    allow(@browser).to receive(:wait_for_pending_requests) do
                        raise Selenium::WebDriver::Error::WebDriverError
                    end

                    expect(@browser.fire_event( element, :click )).to be_nil
                end
            end
        end

        context 'form' do
            context ':submit' do
                let(:url) { "#{@url}/fire_event/form/onsubmit" }

                def element
                    @browser.selenium.find_element(:tag_name, :form)
                end

                context 'when there is a submit button' do
                    let(:url) { "#{@url}/fire_event/form/submit_button" }
                    let(:inputs) do
                        {
                            name:  'The Dude',
                            email: 'the.dude@abides.com'
                        }
                    end

                    it 'clicks it' do
                        @browser.fire_event element, :submit, inputs: inputs

                        expect(@browser.watir.div( id: 'container-name' ).text).to eq(
                           inputs[:name]
                        )
                        expect(@browser.watir.div( id: 'container-email' ).text).to eq(
                            inputs[:email]
                        )
                    end
                end

                context 'when there is a submit input' do
                    let(:url) { "#{@url}/fire_event/form/submit_input" }
                    let(:inputs) do
                        {
                            name:  'The Dude',
                            email: 'the.dude@abides.com'
                        }
                    end

                    it 'clicks it' do
                        @browser.fire_event element, :submit, inputs: inputs

                        expect(@browser.watir.div( id: 'container-name' ).text).to eq(
                            inputs[:name]
                        )
                        expect(@browser.watir.div( id: 'container-email' ).text).to eq(
                            inputs[:email]
                        )
                    end
                end

                context 'when there is no submit button or input' do
                    let(:url) { "#{@url}/fire_event/form/onsubmit" }
                    let(:inputs) do
                        {
                            name:  'The Dude',
                            email: 'the.dude@abides.com'
                        }
                    end

                    it 'triggers the submit event' do
                        @browser.fire_event element, :submit, inputs: inputs

                        expect(@browser.watir.div( id: 'container-name' ).text).to eq(
                            inputs[:name]
                        )
                        expect(@browser.watir.div( id: 'container-email' ).text).to eq(
                            inputs[:email]
                        )
                    end
                end

                context 'when option' do
                    describe ':inputs' do
                        context 'is given' do
                            let(:inputs) do
                                {
                                    name:  'The Dude',
                                    email: 'the.dude@abides.com'
                                }
                            end

                            before(:each) do
                                @browser.fire_event element, :submit, inputs: inputs
                            end

                            it 'fills in its inputs with the given values' do
                                expect(@browser.watir.div( id: 'container-name' ).text).to eq(
                                    inputs[:name]
                                )
                                expect(@browser.watir.div( id: 'container-email' ).text).to eq(
                                    inputs[:email]
                                )
                            end

                            it 'returns a playable transition' do
                                @browser.load url

                                transition = @browser.fire_event element, :submit, inputs: inputs

                                @browser.load url

                                expect(@browser.watir.div( id: 'container-name' ).text).to be_empty
                                expect(@browser.watir.div( id: 'container-email' ).text).to be_empty

                                transition.play @browser

                                expect(@browser.watir.div( id: 'container-name' ).text).to eq(
                                    inputs[:name]
                                )
                                expect(@browser.watir.div( id: 'container-email' ).text).to eq(
                                    inputs[:email]
                                )
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
                                    expect(@browser.watir.div( id: 'container-name' ).text).to eq(
                                        inputs[:name].recode
                                    )
                                    expect(@browser.watir.div( id: 'container-email' ).text).to eq(
                                        inputs[:email].recode
                                    )
                                end
                            end

                            context 'when one of those inputs is a' do
                                context 'select' do
                                    let(:url) { "#{@url}/fire_event/form/select" }

                                    it 'selects it' do
                                        expect(@browser.watir.div( id: 'container-name' ).text).to eq(
                                            inputs[:name]
                                        )
                                        expect(@browser.watir.div( id: 'container-email' ).text).to eq(
                                            inputs[:email]
                                        )
                                    end
                                end
                            end

                            context 'but has missing values' do
                                let(:inputs) do
                                    { name:  'The Dude' }
                                end

                                it 'leaves those empty' do
                                    expect(@browser.watir.div( id: 'container-name' ).text).to eq(
                                        inputs[:name]
                                    )
                                    expect(@browser.watir.div( id: 'container-email' ).text).to be_empty
                                end

                                it 'returns a playable transition' do
                                    @browser.load url
                                    transition = @browser.fire_event element, :submit, inputs: inputs

                                    @browser.load url

                                    expect(@browser.watir.div( id: 'container-name' ).text).to be_empty
                                    expect(@browser.watir.div( id: 'container-email' ).text).to be_empty

                                    transition.play @browser

                                    expect(@browser.watir.div( id: 'container-name' ).text).to eq(
                                        inputs[:name]
                                    )
                                    expect(@browser.watir.div( id: 'container-email' ).text).to be_empty
                                end
                            end

                            context 'and is empty' do
                                let(:inputs) do
                                    {}
                                end

                                it 'fills in empty values' do
                                    expect(@browser.watir.div( id: 'container-name' ).text).to be_empty
                                    expect(@browser.watir.div( id: 'container-email' ).text).to be_empty
                                end

                                it 'returns a playable transition' do
                                    @browser.load url
                                    transition = @browser.fire_event element, :submit, inputs: inputs

                                    @browser.load url

                                    expect(@browser.watir.div( id: 'container-name' ).text).to be_empty
                                    expect(@browser.watir.div( id: 'container-email' ).text).to be_empty

                                    transition.play @browser

                                    expect(@browser.watir.div( id: 'container-name' ).text).to be_empty
                                    expect(@browser.watir.div( id: 'container-email' ).text).to be_empty
                                end
                            end

                            context 'and has disabled inputs' do
                                let(:url) { "#{@url}/fire_event/form/disabled_inputs" }

                                it 'is skips those inputs' do
                                    expect(@browser.watir.div( id: 'container-name' ).text).to eq(
                                        inputs[:name]
                                    )
                                    expect(@browser.watir.div( id: 'container-email' ).text).to be_empty
                                end
                            end
                        end

                        context 'is not given' do
                            it 'fills in its inputs with sample values' do
                                @browser.load url
                                @browser.fire_event element, :submit

                                expect(@browser.watir.div( id: 'container-name' ).text).to eq(
                                    Arachni::Options.input.value_for_name( 'name' )
                                )
                                expect(@browser.watir.div( id: 'container-email' ).text).to eq(
                                    Arachni::Options.input.value_for_name( 'email' )
                                )
                            end

                            it 'returns a playable transition' do
                                @browser.load url
                                transition = @browser.fire_event element, :submit

                                @browser.load url

                                expect(@browser.watir.div( id: 'container-name' ).text).to be_empty
                                expect(@browser.watir.div( id: 'container-email' ).text).to be_empty

                                transition.play @browser

                                expect(@browser.watir.div( id: 'container-name' ).text).to eq(
                                    Arachni::Options.input.value_for_name( 'name' )
                                )
                                expect(@browser.watir.div( id: 'container-email' ).text).to eq(
                                    Arachni::Options.input.value_for_name( 'email' )
                                )
                            end

                            context 'and has disabled inputs' do
                                let(:url) { "#{@url}/fire_event/form/disabled_inputs" }

                                it 'is skips those inputs' do
                                    @browser.fire_event element, :submit

                                    expect(@browser.watir.div( id: 'container-name' ).text).to eq(
                                        Arachni::Options.input.value_for_name( 'name' )
                                    )
                                    expect(@browser.watir.div( id: 'container-email' ).text).to be_empty
                                end
                            end
                        end
                    end
                end
            end

            context ':fill' do
                before(:each) do
                    @browser.load url
                end

                let(:url) { "#{@url}/fire_event/form/onsubmit" }
                let(:inputs) do
                    {
                        name:  "The Dude",
                        email: "the.dude@abides.com"
                    }
                end

                def element
                    @browser.selenium.find_element(:tag_name, :form)
                end

                it 'fills in the form inputs' do
                    @browser.fire_event element, :fill, inputs: inputs

                    expect(@browser.watir.textarea( name: 'name' ).value).to eq(
                        inputs[:name]
                    )

                    expect(@browser.watir.input( id: 'email' ).value).to eq(
                        inputs[:email]
                    )

                    expect(@browser.watir.div( id: 'container-name' ).text).to be_empty
                    expect(@browser.watir.div( id: 'container-email' ).text).to be_empty
                end

                it 'returns a playable transition' do
                    @browser.load url
                    transition = @browser.fire_event element, :fill, inputs: inputs

                    @browser.load url

                    expect(@browser.watir.textarea( name: 'name' ).value).to be_empty
                    expect(@browser.watir.input( id: 'email' ).value).to be_empty

                    transition.play @browser

                    expect(@browser.watir.textarea( name: 'name' ).value).to eq(
                        inputs[:name]
                    )

                    expect(@browser.watir.input( id: 'email' ).value).to eq(
                        inputs[:email]
                    )
                end
            end

            context 'image button' do
                context ':click' do
                    before( :each ) { @browser.start_capture }
                    let(:url) { "#{@url}fire_event/form/image-input" }

                    def element
                        @browser.selenium.find_element( :xpath, '//input[@type="image"]')
                    end

                    it 'submits the form with x, y coordinates' do
                        @browser.load( url )
                        @browser.fire_event element, :click

                        pages_should_have_form_with_input @browser.captured_pages, 'myImageButton.x'
                        pages_should_have_form_with_input @browser.captured_pages, 'myImageButton.y'
                    end

                    it 'returns a playable transition' do
                        @browser.load( url )
                        transition = @browser.fire_event element, :click

                        captured_pages = @browser.flush_pages
                        pages_should_have_form_with_input captured_pages, 'myImageButton.x'
                        pages_should_have_form_with_input captured_pages, 'myImageButton.y'
                        @browser.shutdown

                        @browser = described_class.new.start_capture
                        @browser.load( url )
                        expect(@browser.flush_pages.size).to eq(1)

                        transition.play @browser
                        captured_pages = @browser.flush_pages
                        pages_should_have_form_with_input captured_pages, 'myImageButton.x'
                        pages_should_have_form_with_input captured_pages, 'myImageButton.y'
                    end
                end
            end
        end

        context 'input' do
            [
                :onselect,
                :onchange,
                :onfocus,
                :onblur,
                :onkeydown,
                :onkeypress,
                :onkeyup,
                :oninput
            ].each do |event|
                calculate_expectation = proc do |string|
                    [:onkeypress, :onkeydown].include?( event ) ?
                        string[0...-1] : string
                end

                context event.to_s do
                    let( :url ) { "#{@url}/fire_event/input/#{event}" }

                    context 'when option' do
                        describe ':inputs' do
                            def element
                                @browser.selenium.find_element(:tag_name, :input)
                            end

                            context 'is given' do
                                let(:value) do
                                    'The Dude'
                                end

                                before(:each) do
                                    @browser.fire_event element, event, value: value
                                end

                                it 'fills in its inputs with the given values' do
                                    expect(@browser.watir.div( id: 'container' ).text).to eq(
                                        calculate_expectation.call( value )
                                    )
                                end

                                it 'returns a playable transition' do
                                    @browser.load url
                                    transition = @browser.fire_event element, event, value: value

                                    @browser.load url
                                    expect(@browser.watir.div( id: 'container' ).text).to be_empty

                                    transition.play @browser
                                    expect(@browser.watir.div( id: 'container' ).text).to eq(
                                        calculate_expectation.call( value )
                                    )
                                end

                                context 'and is empty' do
                                    let(:value) do
                                        ''
                                    end

                                    it 'fills in empty values' do
                                        expect(@browser.watir.div( id: 'container' ).text).to be_empty
                                    end

                                    it 'returns a playable transition' do
                                        @browser.load url
                                        transition = @browser.fire_event element, event, value: value

                                        @browser.load url
                                        expect(@browser.watir.div( id: 'container' ).text).to be_empty

                                        transition.play @browser
                                        expect(@browser.watir.div( id: 'container' ).text).to be_empty
                                    end
                                end
                            end

                            context 'is not given' do
                                it 'fills in a sample value' do
                                    @browser.fire_event element, event

                                    expect(@browser.watir.div( id: 'container' ).text).to eq(
                                        calculate_expectation.call( Arachni::Options.input.value_for_name( 'name' ) )
                                    )
                                end

                                it 'returns a playable transition' do
                                    @browser.load url
                                    transition = @browser.fire_event element, event

                                    @browser.load url
                                    expect(@browser.watir.div( id: 'container' ).text).to be_empty

                                    transition.play @browser
                                    expect(@browser.watir.div( id: 'container' ).text).to eq(
                                        calculate_expectation.call( Arachni::Options.input.value_for_name( 'name' ) )
                                    )
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
            expect(elements_with_events).to eq([
                [
                    described_class::ElementLocator.new(
                        tag_name:   'body',
                        attributes: { 'onmouseover' => 'makePOST();' }
                    ),
                    { mouseover: ['makePOST();'] }
                ],
                [
                    described_class::ElementLocator.new(
                        tag_name:   'div',
                        attributes: { 'id' => 'my-div', 'onclick' => 'addForm();' }
                    ),
                    { click: ['addForm();']}
                ]
            ])
        end

        context ':a' do
            context 'and the href is not empty' do
                context 'and it starts with javascript:' do
                    let(:url) { @url + '/each_element_with_events/a/href/javascript' }

                    it 'includes the :click event' do
                        expect(elements_with_events).to eq([
                            [
                                described_class::ElementLocator.new(
                                    tag_name:   'a',
                                    attributes: { 'href' => 'javascript:doStuff()' }
                                ),
                                {click: [ 'javascript:doStuff()']}
                            ]
                        ])
                    end
                end

                context 'and it does not start with javascript:' do
                    let(:url) { @url + '/each_element_with_events/a/href/regular' }

                    it 'is ignored' do
                        expect(elements_with_events).to be_empty
                    end
                end

                context 'and is out of scope' do
                    let(:url) { @url + '/each_element_with_events/a/href/out-of-scope' }

                    it 'is ignored' do
                        expect(elements_with_events).to be_empty
                    end
                end
            end
        end

        context ':form' do
            context ':input' do
                context 'of type "image"' do
                    let(:url) { @url + '/each_element_with_events/form/input/image' }

                    it 'includes the :click event' do
                        expect(elements_with_events).to eq([
                            [
                                described_class::ElementLocator.new(
                                    tag_name:   'input',
                                    attributes: {
                                        'type' => 'image',
                                        'name' => 'myImageButton',
                                        'src'  => '/__sinatra__/404.png'
                                    }
                                ),
                                {click: ['image']}
                            ]
                        ])
                    end
                end
            end

            context 'and the action is not empty' do
                context 'and it starts with javascript:' do
                    let(:url) { @url + '/each_element_with_events/form/action/javascript' }

                    it 'includes the :submit event' do
                        expect(elements_with_events).to eq([
                            [
                                described_class::ElementLocator.new(
                                    tag_name:   'form',
                                    attributes: {
                                        'action' => 'javascript:doStuff()'
                                    }
                                ),
                                {submit: ['javascript:doStuff()']}
                            ]
                        ])
                    end
                end

                context 'and it does not start with javascript:' do
                    let(:url) { @url + '/each_element_with_events/form/action/regular' }

                    it 'is ignored' do
                        expect(elements_with_events).to be_empty
                    end
                end

                context 'and is out of scope' do
                    let(:url) { @url + '/each_element_with_events/form/action/out-of-scope' }

                    it 'is ignored' do
                        expect(elements_with_events).to be_empty
                    end
                end
            end
        end
    end

    describe '#trigger_event' do
        it 'triggers the given event on the given tag and captures snapshots' do
            @browser.load( @url + '/trigger_events' ).start_capture

            locators = []
            @browser.selenium.find_elements(:css, '*').each do |element|
                begin
                    locators << described_class::ElementLocator.from_html( element.opening_tag )
                rescue
                end
            end

            locators.each do |element|
                described_class::Javascript::EVENTS.each do |e|
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

        it 'returns self' do
            expect(@browser.load( @url + '/explore' ).trigger_events).to eq(@browser)
        end

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

            expect(pages.map(&:dom).map(&:transitions)).to eq([
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
                    { "#{@url}get-ajax?ajax-token=my-token" => :request },
                    { "#{@url}post-ajax" => :request }
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
                    { "#{@url}post-ajax" => :request },
                    { "#{@url}href-ajax" => :request }
                ]
            ].map { |transitions| transitions_from_array( transitions ) })
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

        context 'when OptionGroups::Scope#dom_event_limit' do
            context 'has been set' do
                it 'only triggers that amount of events' do
                    Arachni::Options.scope.dom_event_limit = 1

                    @browser.load( "#{@url}form-with-image-button" ).start_capture.trigger_events

                    expect(@browser.flush_pages.size).to eq 1
                end
            end

            context 'has not been set' do
                it 'triggers all events' do
                    Arachni::Options.scope.dom_event_limit = nil

                    @browser.load( "#{@url}form-with-image-button" ).start_capture.trigger_events

                    expect(@browser.flush_pages.size).to eq 2
                end
            end
        end
    end

    describe '#source' do
        it 'returns the evaluated HTML source' do
            @browser.load @url
            expect(@browser.source).to include( ua )
        end
    end

    describe '#watir' do
        it 'provides access to the Watir::Browser API' do
            expect(@browser.watir).to be_kind_of Watir::Browser
        end
    end

    describe '#selenium' do
        it 'provides access to the Selenium::WebDriver::Driver API' do
            expect(@browser.selenium).to be_kind_of Selenium::WebDriver::Driver
        end
    end

    describe '#goto' do
        it 'loads the given URL' do
            @browser.goto @url
            expect(@browser.source).to include( ua )
        end

        it 'returns a playable transition' do
            transition = @browser.goto( @url )

            @browser.shutdown
            @browser = described_class.new

            transition.play( @browser )

            expect(@browser.source).to include( ua )
        end

        it 'puts the domain in the asset domains list' do
            subject.goto @url
            expect(described_class.asset_domains).to include Arachni::URI( @url ).domain
        end

        it 'does not receive a Content-Security-Policy header' do
            subject.goto "#{@url}/Content-Security-Policy"
            expect(subject.response.code).to eq(200)
            expect(subject.response.headers).not_to include 'Content-Security-Policy'
        end

        context 'when requesting the page URL' do
            it 'does not receive a Date header' do
                subject.goto "#{@url}/Date"
                expect(subject.response.code).to eq(200)
                expect(subject.response.headers).not_to include 'Date'
            end

            it 'does not receive an Etag header' do
                subject.goto "#{@url}/Etag"
                expect(subject.response.code).to eq(200)
                expect(subject.response.headers).not_to include 'Etag'
            end

            it 'does not receive a Cache-Control header' do
                subject.goto "#{@url}/Cache-Control"
                expect(subject.response.code).to eq(200)
                expect(subject.response.headers).not_to include 'Cache-Control'
            end

            it 'does not receive a Last-Modified header' do
                subject.goto "#{@url}/Last-Modified"
                expect(subject.response.code).to eq(200)
                expect(subject.response.headers).not_to include 'Last-Modified'
            end

            it 'does not send If-None-Match request headers' do
                subject.goto "#{@url}/If-None-Match"
                expect(subject.response.code).to eq(200)
                expect(subject.response.request.headers).not_to include 'If-None-Match'

                subject.goto "#{@url}/If-None-Match"
                expect(subject.response.code).to eq(200)
                expect(subject.response.request.headers).not_to include 'If-None-Match'
            end

            it 'does not send If-Modified-Since request headers' do
                subject.goto "#{@url}/If-Modified-Since"
                expect(subject.response.code).to eq(200)
                expect(subject.response.request.headers).not_to include 'If-Modified-Since'

                subject.goto "#{@url}/If-Modified-Since"
                expect(subject.response.code).to eq(200)
                expect(subject.response.request.headers).not_to include 'If-Modified-Since'
            end
        end

        context 'when requesting something other than the page URL' do
            it 'receives a Date header' do
                url = "#{@url}Date"

                response = nil
                subject.on_response do |r|
                    next if r.url == url
                    response = r
                end

                subject.goto url

                expect(response.code).to eq(200)
                expect(response.headers).to include 'Date'
            end

            it 'receives an Etag header' do
                url = "#{@url}Etag"

                response = nil
                subject.on_response do |r|
                    next if r.url == url
                    response = r
                end

                subject.goto url

                expect(response.code).to eq(200)
                expect(response.headers).to include 'Etag'
            end

            it 'receives a Cache-Control header' do
                url = "#{@url}Cache-Control"

                response = nil
                subject.on_response do |r|
                    next if r.url == url
                    response = r
                end

                subject.goto url

                expect(response.code).to eq(200)
                expect(response.headers).to include 'Cache-Control'
            end

            it 'receives a Last-Modified header' do
                url = "#{@url}Last-Modified"

                response = nil
                subject.on_response do |r|
                    next if r.url == url
                    response = r
                end

                subject.goto url

                expect(response.code).to eq(200)
                expect(response.headers).to include 'Last-Modified'
            end

            it 'sends If-None-Match request headers' do
                url = "#{@url}If-None-Match"

                response = nil
                subject.on_response do |r|
                    next if r.url == url
                    response = r
                end

                subject.goto url
                expect(response.request.headers).not_to include 'If-None-Match'

                subject.goto url
                expect(response.request.headers).to include 'If-None-Match'
            end

            it 'sends If-Modified-Since request headers' do
                url = "#{@url}If-Modified-Since"

                response = nil
                subject.on_response do |r|
                    next if r.url == url
                    response = r
                end

                subject.goto url
                expect(response.request.headers).not_to include 'If-Modified-Since'

                subject.goto url
                expect(response.request.headers).to include 'If-Modified-Since'
            end
        end

        context 'when the page requires an asset' do
            before do
                described_class.asset_domains.clear
                subject.goto url
            end

            let(:url) { "#{@url}/asset_domains" }

            %w(link input script img).each do |type|
                context 'via link' do
                    let(:url) { "#{super()}/#{type}" }

                    it 'whitelists it' do
                        expect(described_class.asset_domains).to include "#{type}.stuff"
                    end
                end
            end

            context 'with an extension of' do
                described_class::ASSET_EXTENSIONS.each do |extension|
                    context extension do
                        it 'loads it'
                    end
                end
            end

            context 'without an extension' do
                context 'and has been whitelisted' do
                    it 'loads it'
                end

                context 'and has not been whitelisted' do
                    it 'does not load it'
                end
            end
        end

        context 'when the page has JS timeouts' do
            it 'waits for them to complete' do
                time = Time.now
                subject.goto "#{@url}load_delay"
                waited = Time.now - time

                expect(waited).to be >= subject.load_delay / 1000.0
            end
        end

        context 'when there are outstanding HTTP requests' do
            it 'waits for them to complete' do
                sleep_time = 5
                time = Time.now

                subject.goto "#{@url}/ajax_sleep?sleep=#{sleep_time}"

                expect(Time.now - time).to be >= sleep_time
            end

            context "when requests takes more than #{Arachni::OptionGroups::HTTP}#request_timeout" do
                it 'returns false' do
                    sleep_time = 5
                    Arachni::Options.http.request_timeout = 1_000

                    allow_any_instance_of(Arachni::HTTP::ProxyServer).to receive(:has_connections?){ true }

                    time = Time.now
                    subject.goto "#{@url}/ajax_sleep?sleep=#{sleep_time}"

                    expect(Time.now - time).to be < sleep_time
                end
            end
        end

        context "with #{Arachni::OptionGroups::BrowserCluster}#local_storage" do
            before do
                Arachni::Options.browser_cluster.local_storage = {
                    'name' => 'value'
                }
            end

            it 'sets the data as local storage' do
                subject.load @url
                expect( subject.javascript.run( 'return localStorage.getItem( "name" )' ) ).to eq 'value'
            end
        end

        context "with #{Arachni::OptionGroups::BrowserCluster}#wait_for_elements" do
            before do
                Arachni::Options.browser_cluster.wait_for_elements = {
                    'stuff' => '#matchThis'
                }
            end

            context 'when the URL matches a pattern' do
                it 'waits for the element matching the CSS to appear' do
                    t = Time.now
                    @browser.goto( @url + '/wait_for_elements#stuff/here' )
                    expect(Time.now - t).to be > 5

                    expect(@browser.watir.element( css: '#matchThis' ).tag_name).to eq('button')
                end

                it "waits a maximum of #{Arachni::OptionGroups::BrowserCluster}#job_timeout" do
                    Arachni::Options.browser_cluster.job_timeout = 2

                    t = Time.now
                    @browser.goto( @url + '/wait_for_elements#stuff/here' )
                    expect(Time.now - t).to be < 5

                    expect do
                        @browser.watir.element( css: '#matchThis' ).tag_name
                    end.to raise_error Watir::Exception::UnknownObjectException
                end
            end

            context 'when the URL does not match any patterns' do
                it 'does not wait' do
                    t = Time.now
                    @browser.goto( @url + '/wait_for_elements' )
                    expect(Time.now - t).to be < 5

                    expect do
                        @browser.watir.element( css: '#matchThis' ).tag_name
                    end.to raise_error Watir::Exception::UnknownObjectException
                end
            end
        end

        context "#{Arachni::OptionGroups::BrowserCluster}#ignore_images" do
            context 'true' do
                it 'does not load images' do
                    Arachni::Options.browser_cluster.ignore_images = true
                    @browser.shutdown
                    @browser = described_class.new( disk_cache: false )

                    @browser.load( "#{@url}form-with-image-button" )

                    expect(image_hit_count).to eq(0)
                end
            end

            context 'false' do
                it 'loads images' do
                    Arachni::Options.browser_cluster.ignore_images = false
                    @browser.shutdown
                    @browser = described_class.new( disk_cache: false )

                    @browser.load( "#{@url}form-with-image-button" )

                    expect(image_hit_count).to eq(1)
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
                Arachni::Options.scope.redundant_path_patterns = { 'explore' => 0 }
                expect(@browser.load( @url + '/explore' ).response.code).to eq(0)
            end
        end

        context "with #{Arachni::OptionGroups::Scope}#auto_redundant_paths has bee configured" do
            it 'respects scope restrictions' do
                Arachni::Options.scope.auto_redundant_paths = 0
                expect(@browser.load( @url + '/explore?test=1&test2=2' ).response).to be_nil
            end
        end

        describe ':cookies' do
            it 'loads the given cookies' do
                cookie = { 'myname' => 'myvalue' }
                @browser.goto @url, cookies: cookie

                cookie_data = @browser.cookies.
                    find { |c| c.name == cookie.keys.first }.inputs

                expect(cookie_data).to eq(cookie)
            end

            it 'includes them in the transition' do
                cookie = { 'myname' => 'myvalue' }
                transition = @browser.goto( @url, cookies: cookie )

                expect(transition.options[:cookies]).to eq(cookie)
            end
        end

        describe ':take_snapshot' do
            describe 'true' do
                it 'captures a snapshot of the loaded page' do
                    @browser.goto @url, take_snapshot: true
                    pages = @browser.page_snapshots
                    expect(pages.size).to eq(1)

                    expect(pages.first.dom.transitions).to eq(transitions_from_array([
                        { page: :load },
                        { @url => :request }
                    ]))
                end
            end

            describe 'false' do
                it 'does not capture a snapshot of the loaded page' do
                    @browser.goto @url, take_snapshot:  false
                    expect(@browser.page_snapshots).to be_empty
                end
            end

            describe 'default' do
                it 'captures a snapshot of the loaded page' do
                    @browser.goto @url
                    pages = @browser.page_snapshots
                    expect(pages.size).to eq(1)

                    expect(pages.first.dom.transitions).to eq(transitions_from_array([
                        { page: :load },
                        { @url => :request }
                    ]))
                end
            end
        end

        describe ':update_transitions' do
            describe 'true' do
                it 'pushes the page load to the transitions' do
                    t = @browser.goto( @url, update_transitions: true )
                    expect(@browser.to_page.dom.transitions).to include t
                end
            end

            describe 'false' do
                it 'does not push the page load to the transitions' do
                    t = @browser.goto( @url, update_transitions: false )
                    expect(@browser.to_page.dom.transitions).to be_empty
                end
            end

            describe 'default' do
                it 'pushes the page load to the transitions' do
                    t = @browser.goto( @url )
                    expect(@browser.to_page.dom.transitions).to include t
                end
            end
        end
    end

    describe '#load' do
        it 'returns self' do
            expect(@browser.load( @url )).to eq(@browser)
        end

        it 'updates the global cookie-jar' do
            @browser.load @url

            cookie = Arachni::HTTP::Client.cookies.find(&:http_only?)

            expect(cookie.name).to  eq('This name should be updated; and properly escaped')
            expect(cookie.value).to eq('This value should be updated; and properly escaped')
        end

        describe ':cookies' do
            it 'loads the given cookies' do
                cookie = { 'myname' => 'myvalue' }
                @browser.load @url, cookies: cookie

                expect(@browser.cookies.find { |c| c.name == cookie.keys.first }.inputs).to eq(cookie)
            end
        end

        describe ':take_snapshot' do
            describe 'true' do
                it 'captures a snapshot of the loaded page' do
                    @browser.load @url, take_snapshot: true
                    pages = @browser.page_snapshots
                    expect(pages.size).to eq(1)

                    expect(pages.first.dom.transitions).to eq(transitions_from_array([
                        { page: :load },
                        { @url => :request }
                    ]))
                end
            end

            describe 'false' do
                it 'does not capture a snapshot of the loaded page' do
                    @browser.load @url, take_snapshot: false
                    expect(@browser.page_snapshots).to be_empty
                end
            end

            describe 'default' do
                it 'captures a snapshot of the loaded page' do
                    @browser.load @url
                    pages = @browser.page_snapshots
                    expect(pages.size).to eq(1)

                    expect(pages.first.dom.transitions).to eq(transitions_from_array([
                        { page: :load },
                        { @url => :request }
                    ]))
                end
            end
        end

        context 'when given a' do
            describe 'String' do
                it 'treats it as a URL' do
                    expect(hit_count).to eq(0)

                    @browser.load @url
                    expect(@browser.source).to include( ua )
                    expect(@browser.preloads).not_to include( @url )

                    expect(hit_count).to eq(1)
                end
            end

            describe 'Arachni::HTTP::Response' do
                it 'loads it' do
                    expect(hit_count).to eq(0)

                    @browser.load Arachni::HTTP::Client.get( @url, mode: :sync )
                    expect(@browser.source).to include( ua )
                    expect(@browser.preloads).not_to include( @url )

                    expect(hit_count).to eq(1)
                end
            end

            describe 'Arachni::Page::DOM' do
                it 'loads it' do
                    expect(hit_count).to eq(0)

                    page = Arachni::HTTP::Client.get( @url, mode: :sync ).to_page

                    expect(hit_count).to eq(1)

                    @browser.load page.dom

                    expect(@browser.source).to include( ua )
                    expect(@browser.preloads).not_to include( @url )

                    expect(hit_count).to eq(2)
                end

                it 'replays its #transitions' do
                    @browser.load "#{@url}play-transitions"
                    page = @browser.explore_and_flush.last
                    expect(page.body).to include ua

                    @browser.load page.dom
                    expect(@browser.source).to include ua

                    page.dom.transitions.clear
                    @browser.load page.dom
                    expect(@browser.source).not_to include ua
                end

                it 'loads its #skip_states' do
                    @browser.load( @url )
                    pages = @browser.load( @url + '/explore' ).trigger_events.
                        page_snapshots

                    page = pages.last
                    expect(page.dom.skip_states).to be_subset @browser.skip_states

                    token = @browser.generate_token

                    dpage = page.dup
                    dpage.dom.skip_states << token

                    @browser.load dpage.dom
                    expect(@browser.skip_states).to include token
                end
            end

            describe 'Arachni::Page' do
                it 'loads it' do
                    expect(hit_count).to eq(0)

                    page = Arachni::HTTP::Client.get( @url, mode: :sync ).to_page

                    expect(hit_count).to eq(1)

                    @browser.load page

                    expect(@browser.source).to include( ua )
                    expect(@browser.preloads).not_to include( @url )

                    expect(hit_count).to eq(2)
                end

                it 'uses its #cookie_jar' do
                    expect(@browser.cookies).to be_empty

                    cookie = Arachni::Cookie.new(
                        url:    @url,
                        inputs: {
                            'my-name' => 'my-value'
                        }
                    )

                    page = Arachni::Page.from_data(
                        url:        @url,
                        cookie_jar:  [ cookie ]
                    )

                    expect(@browser.cookies).to_not include cookie

                    @browser.load( page )

                    expect(@browser.cookies).to include cookie
                end

                it 'replays its DOM#transitions' do
                    @browser.load "#{@url}play-transitions"
                    page = @browser.explore_and_flush.last
                    expect(page.body).to include ua

                    @browser.load page
                    expect(@browser.source).to include ua

                    page.dom.transitions.clear
                    @browser.load page
                    expect(@browser.source).not_to include ua
                end

                it 'loads its DOM#skip_states' do
                    @browser.load( @url )
                    pages = @browser.load( @url + '/explore' ).trigger_events.
                        page_snapshots

                    page = pages.last
                    expect(page.dom.skip_states).to be_subset @browser.skip_states

                    token = @browser.generate_token

                    dpage = page.dup
                    dpage.dom.skip_states << token

                    @browser.load dpage
                    expect(@browser.skip_states).to include token
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

            expect(hit_count).to eq(0)

            @browser.load @url
            expect(@browser.source).to include( ua )
            expect(@browser.preloads).not_to include( @url )

            expect(hit_count).to eq(0)

            2.times do
                @browser.load @url
                expect(@browser.source).to include( ua )
            end

            expect(@browser.preloads).not_to include( @url )

            expect(hit_count).to eq(2)
        end

        it 'returns the URL of the resource' do
            response = Arachni::HTTP::Client.get( @url, mode: :sync )
            expect(@browser.preload( response )).to eq(response.url)

            @browser.load response.url
            expect(@browser.source).to include( ua )
        end

        context 'when given a' do
            describe 'Arachni::HTTP::Response' do
                it 'preloads it' do
                    @browser.preload Arachni::HTTP::Client.get( @url, mode: :sync )
                    clear_hit_count

                    expect(hit_count).to eq(0)

                    @browser.load @url
                    expect(@browser.source).to include( ua )
                    expect(@browser.preloads).not_to include( @url )

                    expect(hit_count).to eq(0)
                end
            end

            describe 'Arachni::Page' do
                it 'preloads it' do
                    @browser.preload Arachni::Page.from_url( @url )
                    clear_hit_count

                    expect(hit_count).to eq(0)

                    @browser.load @url
                    expect(@browser.source).to include( ua )
                    expect(@browser.preloads).not_to include( @url )

                    expect(hit_count).to eq(0)
                end
            end

            describe 'other' do
                it 'raises Arachni::Browser::Error::Load' do
                    expect { @browser.preload [] }.to raise_error Arachni::Browser::Error::Load
                end
            end
        end
    end

    describe '#start_capture' do
        before(:each) { @browser.start_capture }

        it 'parses requests into elements of pages' do
            @browser.load @url + '/with-ajax'

            pages = @browser.captured_pages
            expect(pages.size).to eq(2)

            page = pages.first
            expect(page.forms.find { |form| form.inputs.include? 'ajax-token' }).to be_truthy
        end

        context 'when an element has already been seen' do
            context 'by the browser' do
                it 'ignores it' do
                    @browser.load @url + '/with-ajax'
                    expect(@browser.captured_pages.size).to eq(2)
                    @browser.captured_pages.clear

                    @browser.load @url + '/with-ajax'
                    expect(@browser.captured_pages).to be_empty
                end
            end

            context "by the #{Arachni::ElementFilter}" do
                it 'ignores it' do
                    @browser.load @url + '/with-ajax'
                    Arachni::ElementFilter.update_forms @browser.captured_pages.map(&:forms).flatten
                    @browser.shutdown

                    @browser = described_class.new
                    @browser.load @url + '/with-ajax'
                    expect(@browser.captured_pages).to be_empty
                end
            end
        end

        context 'when a GET request is performed' do
            it "is added as an #{Arachni::Element::Form} to the page" do
                @browser.load @url + '/with-ajax'

                pages = @browser.captured_pages
                expect(pages.size).to eq(2)

                page = pages.first

                form = page.forms.find { |form| form.inputs.include? 'ajax-token' }

                expect(form.url).to eq(@url + 'with-ajax')
                expect(form.action).to eq(@url + 'get-ajax')
                expect(form.inputs).to eq({ 'ajax-token' => 'my-token' })
                expect(form.method).to eq(:get)
            end
        end

        context 'when a POST request is performed' do
            context 'with query parameters' do
                it "is added as an #{Arachni::Element::Form} to the page" do
                    @browser.load @url + '/with-ajax'

                    pages = @browser.captured_pages
                    expect(pages.size).to eq(2)

                    form = find_page_with_form_with_input( pages, 'post-name' ).
                        forms.find { |form| form.inputs.include? 'post-query' }

                    expect(form.url).to eq(@url + 'with-ajax')
                    expect(form.action).to eq(@url + 'post-ajax')
                    expect(form.inputs).to eq({ 'post-query' => 'blah' })
                    expect(form.method).to eq(:get)
                end
            end

            context 'with form data' do
                it "is added as an #{Arachni::Element::Form} to the page" do
                    @browser.load @url + '/with-ajax'

                    pages = @browser.captured_pages
                    expect(pages.size).to eq(2)

                    form = find_page_with_form_with_input( pages, 'post-name' ).
                        forms.find { |form| form.inputs.include? 'post-name' }

                    expect(form.url).to eq(@url + 'with-ajax')
                    expect(form.action).to eq(@url + 'post-ajax?post-query=blah')
                    expect(form.inputs).to eq({ 'post-name' => 'post-value' })
                    expect(form.method).to eq(:post)
                end
            end

            context 'with JSON data' do
                it "is added as an #{Arachni::Element::JSON} to the page" do
                    @browser.load @url + '/with-ajax-json'

                    pages = @browser.captured_pages
                    expect(pages.size).to eq(1)

                    form = find_page_with_json_with_input( pages, 'post-name' ).
                        jsons.find { |json| json.inputs.include? 'post-name' }

                    expect(form.url).to eq(@url + 'with-ajax-json')
                    expect(form.action).to eq(@url + 'post-ajax')
                    expect(form.inputs).to eq({ 'post-name' => 'post-value' })
                    expect(form.method).to eq(:post)
                end
            end

            context 'with XML data' do
                it "is added as an #{Arachni::Element::XML} to the page" do
                    @browser.load @url + '/with-ajax-xml'

                    pages = @browser.captured_pages
                    expect(pages.size).to eq(1)

                    form = find_page_with_xml_with_input( pages, 'input > text()' ).
                        xmls.find { |xml| xml.inputs.include? 'input > text()' }

                    expect(form.url).to eq(@url + 'with-ajax-xml')
                    expect(form.action).to eq(@url + 'post-ajax')
                    expect(form.inputs).to eq({ 'input > text()' => 'stuff' })
                    expect(form.method).to eq(:post)
                end
            end
        end
    end

    describe '#flush_pages' do
        it 'flushes the captured pages' do
            @browser.start_capture
            @browser.load @url + '/with-ajax'

            pages = @browser.flush_pages
            expect(pages.size).to eq(3)
            expect(@browser.flush_pages).to be_empty
        end
    end

    describe '#stop_capture' do
        it 'stops the page capture' do
            @browser.stop_capture
            expect(@browser.capture?).to be_falsey
        end
    end

    describe 'capture?' do
        it 'returns false' do
            @browser.start_capture
            @browser.stop_capture
            expect(@browser.capture?).to be_falsey
        end

        context 'when capturing pages' do
            it 'returns true' do
                @browser.start_capture
                expect(@browser.capture?).to be_truthy
            end
        end
        context 'when not capturing pages' do
            it 'returns false' do
                @browser.start_capture
                @browser.stop_capture
                expect(@browser.capture?).to be_falsey
            end
        end
    end

    describe '#cookies' do
        it 'returns cookies visible via JavaScript' do
            @browser.load @url

            cookie = @browser.cookies.first
            expect(cookie.name).to  eq 'cookie_name'
            expect(cookie.value).to eq 'cookie value'
            expect(cookie.raw_name).to  eq 'cookie_name'
            expect(cookie.raw_value).to eq '"cookie value"'
        end

        it 'preserves expiration value' do
            @browser.load "#{@url}/cookies/expires"

            cookie = @browser.cookies.first
            expect(cookie.name).to  eq 'without_expiration'
            expect(cookie.value).to eq 'stuff'
            expect(cookie.expires).to be_nil

            cookie = @browser.cookies.last
            expect(cookie.name).to  eq 'with_expiration'
            expect(cookie.value).to eq 'bar'
            expect(cookie.expires.to_s).to eq Time.parse( '2047-08-01 09:30:11 +0000' ).to_s
        end

        it 'preserves the domain' do
            @browser.load "#{@url}/cookies/domains"

            cookies = @browser.cookies

            cookie = cookies.find { |c| c.name == 'include_subdomains' }
            expect(cookie.name).to  eq 'include_subdomains'
            expect(cookie.value).to eq 'bar1'
            expect(cookie.domain).to eq ".#{Arachni::URI( @url ).host}"
        end

        it 'ignores cookies for other domains' do
            @browser.load "#{@url}/cookies/domains"

            cookies = @browser.cookies
            expect(cookies.find { |c| c.name == 'other_domain' }).to be_nil
        end

        it 'preserves the path' do
            @browser.load "#{@url}/cookies/under/path"

            cookie = @browser.cookies.first
            expect(cookie.name).to  eq 'cookie_under_path'
            expect(cookie.value).to eq 'value'
            expect(cookie.path).to eq '/cookies/under/'
        end

        it 'preserves httpOnly' do
            @browser.load "#{@url}/cookies/under/path"

            cookie = @browser.cookies.first
            expect(cookie.name).to  eq 'cookie_under_path'
            expect(cookie.value).to eq 'value'
            expect(cookie.path).to eq '/cookies/under/'
            expect(cookie).to_not be_http_only

            @browser.load "#{@url}/cookies/httpOnly"

            cookie = @browser.cookies.first
            expect(cookie.name).to  eq 'http_only'
            expect(cookie.value).to eq 'stuff'
            expect(cookie).to be_http_only
        end

        context 'when parsing v1 cookies' do
            it 'removes the quotes' do
                cookie = 'rsession="06142010_0%3Ae275d357943e9a2de0"'

                @browser.load @url
                @browser.javascript.run( "document.cookie = '#{cookie}';" )

                cookie = @browser.cookies.find { |c| c.name == 'rsession' }
                expect(cookie.value).to eq('06142010_0:e275d357943e9a2de0')
                expect(cookie.raw_value).to eq('"06142010_0%3Ae275d357943e9a2de0"')
            end
        end

        context 'when no page is available' do
            it 'returns an empty Array' do
                expect(@browser.cookies).to be_empty
            end
        end
    end

end
