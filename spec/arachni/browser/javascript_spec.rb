require 'spec_helper'

describe Arachni::Browser::Javascript do

    before( :all ) do
        @dom_monitor_url  = Arachni::Utilities.normalize_url( web_server_url_for( :dom_monitor ) )
        @taint_tracer_url = Arachni::Utilities.normalize_url( web_server_url_for( :taint_tracer ) )
    end

    before( :each ) do
        @browser = Arachni::Browser.new
    end

    after( :each ) do
        Arachni::Options.reset
        @browser.shutdown
        Arachni::Browser.asset_domains.clear
    end

    subject { @browser.javascript }

    describe '#wait_till_ready' do
        it 'waits until the JS environment is #ready?'

        context 'when it exceeds Options.browser_cluster.job_timeout' do
            it 'returns' do
                Arachni::Options.browser_cluster.job_timeout = 5
                t = Time.now

                @browser.load "#{@taint_tracer_url}/debug"

                allow(subject).to receive(:ready?) { false }

                subject.wait_till_ready

                expect(Time.now - t).to be > 5
                expect(Time.now - t).to be < 6
            end
        end
    end

    describe '#dom_monitor' do
        it 'provides access to the DOMMonitor javascript interface' do
            @browser.load "#{@taint_tracer_url}/debug"
            expect(subject.dom_monitor.js_object).to end_with 'DOMMonitor'
        end
    end

    describe '#taint_tracer' do
        it 'provides access to the TaintTracer javascript interface' do
            @browser.load "#{@taint_tracer_url}/debug"
            expect(subject.taint_tracer.js_object).to end_with 'TaintTracer'
        end
    end

    describe '#custom_code' do
        it 'injects the given code into the response' do
            subject.custom_code = 'window.has_custom_code = true'
            @browser.load "#{@taint_tracer_url}/debug"
            expect(subject.run( 'return window.has_custom_code' )).to eq(true)
        end
    end

    describe '#log_execution_flow_sink_stub' do
        it 'returns JS code for TaintTracer.log_execution_flow_sink()' do
            expect(subject.log_execution_flow_sink_stub( 1, 2, 3 )).to eq(
                "_#{subject.token}TaintTracer.log_execution_flow_sink(1, 2, 3)"
            )
        end
    end

    describe '#log_data_flow_sink_stub' do
        it 'returns JS code for TaintTracer.log_data_flow_sink()' do
            expect(subject.log_data_flow_sink_stub( 1, 2, 3 )).to eq(
                "_#{subject.token}TaintTracer.log_data_flow_sink(1, 2, 3)"
            )
        end
    end

    describe '#debug_stub' do
        it 'returns JS code for TaintTracer.debug()' do
            expect(subject.debug_stub( 1, 2, 3 )).to eq(
                "_#{subject.token}TaintTracer.debug(1, 2, 3)"
            )
        end
    end

    describe '#supported?' do
        context 'when there is support for the Javascript environment' do
            it 'returns true' do
                @browser.load "#{@taint_tracer_url}/debug"
                expect(subject.supported?).to be_truthy
            end
        end

        context 'when there is no support for the Javascript environment' do
            it 'returns false' do
                @browser.load "#{@taint_tracer_url}/without_javascript_support"
                expect(subject.supported?).to be_falsey
            end
        end

        context 'when the resource is out-of-scope' do
            it 'returns false' do
                Arachni::Options.url = @taint_tracer_url
                @browser.load 'http://google.com/'
                expect(subject.supported?).to be_falsey
            end
        end
    end

    describe '#log_execution_flow_sink_stub' do
        it 'returns JS code that calls JS\'s log_execution_flow_sink_stub()' do
            expect(subject.log_execution_flow_sink_stub).to eq(
                "_#{subject.token}TaintTracer.log_execution_flow_sink()"
            )

            @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_execution_flow_sink_stub}"

            @browser.watir.form.submit
            expect(subject.execution_flow_sinks).to be_any
            expect(subject.execution_flow_sinks.first.data).to be_empty
        end
    end

    describe '#set_element_ids' do
        it 'sets custom ID attributes to elements with events but without ID' do
            @browser.load( @dom_monitor_url + 'set_element_ids' )

            as = @browser.watir.as

            expect(as[0].name).to eq('1')
            expect(as[0].html).not_to include 'data-arachni-id'

            expect(as[1].name).to eq('2')
            expect(as[1].html).to include 'data-arachni-id'

            expect(as[2].name).to eq('3')
            expect(as[2].html).not_to include 'data-arachni-id'

            expect(as[3].name).to eq('4')
            expect(as[3].html).not_to include 'data-arachni-id'
        end
    end

    describe '#dom_digest' do
        it 'returns a string digest of the current DOM tree' do
            @browser.load( @dom_monitor_url + 'digest' )
            expect(subject.dom_digest).to eq(subject.dom_monitor.digest)
        end
    end

    describe '#each_dom_element_with_events' do
        context 'when given a whitelist of tag names' do
            it 'only returns those types of elements' do
                @browser.load @dom_monitor_url + 'elements_with_events/whitelist'

                e = []
                subject.each_dom_element_with_events ['span'] do |element|
                    e << element
                end

                expect(e).to eq([
                    {
                     'tag_name'   => 'span',
                     'events'     =>
                         {
                             click: [
                                 'function (parent_click) {}',
                                 'function (child_click) {}',
                                 'function (window_click) {}',
                                 'function (document_click) {}'
                             ]
                         },
                     'attributes' => { 'id' => 'child-span' }
                    }
                ])
            end
        end

        context 'when using event attributes' do
            it 'returns information about all DOM elements along with their events' do
                @browser.load @dom_monitor_url + 'elements_with_events/attributes'

                e = []
                subject.each_dom_element_with_events do |element|
                    e << element
                end

                expect(e).to eq([
                    {
                        'tag_name'   => 'button',
                        'events'     => {
                            click: [ 'handler_1()' ]
                        },
                        'attributes' => { 'onclick' => 'handler_1()', 'id' => 'my-button' }
                    },
                    {
                        'tag_name'   => 'button',
                        'events'     => {
                            click: ['handler_2()']
                        },
                        'attributes' => { 'onclick' => 'handler_2()', 'id' => 'my-button2' }
                    },
                    {
                        'tag_name'   => 'button',
                        'events'     => {
                            click: ['handler_3()']
                        },
                        'attributes' => { 'onclick' => 'handler_3()', 'id' => 'my-button3' }
                    }
                ])
            end

            context 'with inappropriate events for the element' do
                it 'ignores them' do
                    @browser.load @dom_monitor_url + 'elements_with_events/attributes/inappropriate'

                    e = []
                    subject.each_dom_element_with_events do |element|
                        e << element
                    end

                    expect(e).to be_empty
                end
            end
        end

        context 'when using event listeners' do
            it 'returns information about all DOM elements along with their events' do
                @browser.load @dom_monitor_url + 'elements_with_events/listeners'

                e = []
                subject.each_dom_element_with_events do |element|
                    e << element
                end

                expect(e).to eq([
                    {
                        'tag_name'   => 'button',
                        'events'     => {
                            click: ['function (my_button_click) {}', 'function (my_button_click2) {}'],
                            mouseover: ['function (my_button_onmouseover) {}']
                        },
                        'attributes' => { 'id' => 'my-button' } },
                    {
                        'tag_name'   => 'button',
                        'events'     => {
                            click: ['function (my_button2_click) {}']
                        },
                        'attributes' => { 'id' => 'my-button2' } }
                ])
            end

            it 'does not include custom events' do
                @browser.load @dom_monitor_url + 'elements_with_events/listeners/custom'

                e = []
                subject.each_dom_element_with_events do |element|
                    e << element
                end

                expect(e).to be_empty
            end

            context 'with inappropriate events for the element' do
                it 'ignores them' do
                    @browser.load @dom_monitor_url + 'elements_with_events/listeners/inappropriate'

                    e = []
                    subject.each_dom_element_with_events do |element|
                        e << element
                    end

                    expect(e).to be_empty
                end
            end
        end
    end

    describe '#timeouts' do
        it 'keeps track of setTimeout() timers' do
            @browser.load( @dom_monitor_url + 'timeout-tracker' )
            expect(subject.timeouts).to eq(subject.dom_monitor.timeouts)
        end
    end

    describe '#has_sinks?' do
        context 'when there are execution-flow sinks' do
            it 'returns true' do
                expect(subject).to_not have_sinks

                @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_execution_flow_sink_stub(1)}"
                @browser.watir.form.submit

                expect(subject).to have_sinks
            end
        end

        context 'when there are data-flow sinks' do
            context 'for the given taint' do
                it 'returns true' do
                    expect(subject).to_not have_sinks

                    subject.taint = 'taint'
                    @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_data_flow_sink_stub( subject.taint, function: { name: 'blah' } )}"
                    @browser.watir.form.submit

                    expect(subject).to have_sinks
                end
            end

            context 'for other taints' do
                it 'returns false' do
                    expect(subject).to_not have_sinks

                    subject.taint = 'taint'
                    @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_data_flow_sink_stub( subject.taint, function: { name: 'blah' } )}"
                    @browser.watir.form.submit

                    subject.taint = 'taint2'
                    expect(subject).to_not have_sinks
                end
            end
        end

        context 'when there are no sinks' do
            it 'returns false' do
                expect(subject).to_not have_sinks
            end
        end
    end

    describe '#debugging_data' do
        it 'returns debugging information' do
            @browser.load "#{@taint_tracer_url}/debug?input=#{subject.debug_stub(1)}"
            @browser.watir.form.submit
            expect(subject.debugging_data).to eq(subject.taint_tracer.debugging_data)
        end
    end

    describe '#execution_flow_sinks' do
        it 'returns sink data' do
            @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_execution_flow_sink_stub(1)}"
            @browser.watir.form.submit

            expect(subject.execution_flow_sinks).to be_any
            expect(subject.execution_flow_sinks).to eq(subject.taint_tracer.execution_flow_sinks)
        end
    end

    describe '#data_flow_sinks' do
        it 'returns sink data' do
            @browser.javascript.taint = 'taint'
            @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_data_flow_sink_stub( @browser.javascript.taint, function: { name: 'blah' } )}"
            @browser.watir.form.submit

            sinks = subject.data_flow_sinks
            expect(sinks).to be_any
            expect(sinks).to eq(subject.taint_tracer.data_flow_sinks[@browser.javascript.taint])
        end
    end

    describe '#flush_data_flow_sinks' do
        before do
            @browser.javascript.taint = 'taint'
        end

        it 'returns sink data' do
            @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_data_flow_sink_stub( @browser.javascript.taint, function: { name: 'blah' } )}"
            @browser.watir.form.submit

            sink = subject.flush_data_flow_sinks
            sink[0].trace[1].function.arguments[0].delete( 'timeStamp' )

            @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_data_flow_sink_stub( @browser.javascript.taint, function: { name: 'blah' } )}"
            @browser.watir.form.submit

            sink2 = subject.taint_tracer.data_flow_sinks[@browser.javascript.taint]
            sink2[0].trace[1].function.arguments[0].delete( 'timeStamp' )

            expect(sink).to eq(sink2)
        end

        it 'empties the sink' do
            @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_data_flow_sink_stub}"
            @browser.watir.form.submit

            subject.flush_data_flow_sinks
            expect(subject.data_flow_sinks).to be_empty
        end
    end

    describe '#flush_execution_flow_sinks' do
        it 'returns sink data' do
            @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_execution_flow_sink_stub(1)}"
            @browser.watir.form.submit

            sink = subject.flush_execution_flow_sinks
            sink[0].trace[1].function.arguments[0].delete( 'timeStamp' )

            @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_execution_flow_sink_stub(1)}"
            @browser.watir.form.submit

            sink2 = subject.taint_tracer.execution_flow_sinks
            sink2[0].trace[1].function.arguments[0].delete( 'timeStamp' )

            expect(sink).to eq(sink2)
        end

        it 'empties the sink' do
            @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_execution_flow_sink_stub}"
            @browser.watir.form.submit

            subject.flush_execution_flow_sinks
            expect(subject.execution_flow_sinks).to be_empty
        end
    end

    describe '#serve' do
        context 'when the request URL is' do
            %W(dom_monitor.js taint_tracer.js).each do |filename|
                url = "#{described_class::SCRIPT_BASE_URL}#{filename}"
                let(:url) { url }
                let(:content_type) { 'text/javascript' }
                let(:body) do
                    IO.read( "#{described_class::SCRIPT_LIBRARY}#{filename}" ).
                        gsub( '_token', "_#{subject.token}" )
                end
                let(:content_length) { body.bytesize.to_s }
                let(:request) { Arachni::HTTP::Request.new( url: url ) }
                let(:response) do
                    Arachni::HTTP::Response.new(
                        url:     url,
                        request: request
                    )
                end

                context url do
                    before(:each){ subject.serve( request, response ) }

                    it 'sets the correct status code' do
                        expect(response.code).to eq(200)
                    end

                    it 'populates the given response body with its contents' do
                        expect(response.body).to eq(body)
                    end

                    it 'sets the correct Content-Type' do
                        expect(response.headers.content_type).to eq(content_type)
                    end

                    it 'sets the correct Content-Length' do
                        expect(response.headers['content-length']).to eq(content_length)
                    end

                    it 'returns true' do
                        expect(subject.serve( request, response )).to be_truthy
                    end
                end
            end

            context 'other' do
                it 'returns false' do
                    request.url = 'stuff'
                    expect(subject.serve( request, response )).to be_falsey
                end
            end
        end
    end

    describe '#inject' do
        context 'when the response is' do
            context 'JavaScript' do
                let(:response) do
                    Arachni::HTTP::Response.new(
                        url:     "#{@dom_monitor_url}/jquery.js",
                        headers: {
                            'Content-Type' => 'text/javascript'
                        },
                        body: <<EOHTML
                    foo()
EOHTML
                    )
                end

                let(:injected) do
                    r = response.deep_clone
                    subject.inject( r )
                    r
                end

                let(:taint_tracer_update) do
                    "#{subject.taint_tracer.stub.function( :update_tracers )};"
                end

                let(:dom_monitor_update) do
                    "#{subject.dom_monitor.stub.function( :update_trackers )};"
                end

                it 'inject a TaintTracer.update_tracers() call before the code' do
                    expect(injected.body.scan( /(.*)foo/m ).flatten.first).to include taint_tracer_update
                end

                it 'inject a DOMMonitor.update_trackers() call before the code' do
                    expect(injected.body.scan( /(.*)foo/m ).flatten.first).to include dom_monitor_update
                end

                it 'appends a semicolon and newline to the body' do
                    expect(injected.body).to include "#{response.body};\n"
                end
            end

            context 'HTML' do
                let(:response) do
                    Arachni::HTTP::Response.new(
                        url:     @dom_monitor_url,
                        headers: {
                            'Content-Type' => 'text/html'
                        },
                        body: <<EOHTML
                    <body>
                    </body>
EOHTML
                    )
                end

                context 'when the response does not already contain the JS code' do
                    it 'injects the system\'s JS interfaces in the response body' do
                        subject.inject( response )

                        %w(taint_tracer dom_monitor).each do |name|
                            src = "#{described_class::SCRIPT_BASE_URL}#{name}.js"
                            expect(Nokogiri::HTML( response.body ).xpath( "//script[@src='#{src}']" )).to be_any
                        end
                    end

                    context 'when the response body contains script elements' do
                        before { response.body = '<script>// My code and stuff</script>' }

                        it 'injects taint tracer update calls at the top of the script' do
                            subject.inject( response )
                            expect(Nokogiri::HTML(response.body).css('script')[-2].to_s).to eq(
                                "<script>

                // Injected by #{described_class}
                _#{subject.token}TaintTracer.update_tracers();
                _#{subject.token}DOMMonitor.update_trackers();

// My code and stuff</script>"
                            )
                        end

                        it 'injects taint tracer update calls after the script' do
                            subject.inject( response )
                            expect(Nokogiri::HTML(response.body).css('script')[-1].to_s).to eq(
                                "<script type=\"text/javascript\">" +
                                "_#{subject.token}TaintTracer.update_tracers();" +
                                "_#{subject.token}DOMMonitor.update_trackers();" +
                                '</script>'
                            )
                        end
                    end
                end

                context 'when the response already contains the JS code' do
                    it 'updates the taints' do
                        subject.inject( response )

                        presponse = response.deep_clone
                        pintializer = subject.taint_tracer.stub.function( :initialize, {} )

                        subject.taint = [ 'taint1', 'taint2' ]
                        subject.inject( response )
                        intializer = subject.taint_tracer.stub.function(
                            :initialize,
                            {
                                "taint1" => { "stop_at_first" => false, "trace" => true },
                                "taint2" => { "stop_at_first" => false, "trace" => true }
                            }
                        )

                        expect(response.body).to eq(presponse.body.gsub( pintializer, intializer ))
                    end

                    it 'updates the custom code' do
                        subject.custom_code = 'alert(1);'
                        subject.inject( response )

                        presponse = response.deep_clone
                        code      = subject.custom_code

                        subject.custom_code = 'alert(2);'
                        subject.inject( response )

                        expect(response.body).to eq(presponse.body.gsub( code, subject.custom_code ))
                    end
                end
            end
        end
    end

    describe '#javascript?' do
        context 'when the Content-Type includes javascript' do
            it 'returns true'
        end

        context 'when the Content-Type does not include javascript' do
            it 'returns false'
        end
    end

    describe '#html?' do
        context 'when the body is empty' do
            it 'returns false'
        end

        context 'when it matches the last loaded URL' do
            it 'returns true'
        end

        context 'when it contains markup' do
            it 'returns true'
        end
    end

    describe '#run' do
        it 'executes the given script under the browser\'s context' do
            @browser.load @dom_monitor_url
            expect(Nokogiri::HTML(@browser.source).to_s).to eq(
                Nokogiri::HTML(subject.run( 'return document.documentElement.innerHTML' ) ).to_s
            )
        end
    end

    describe '#run_without_elements' do
        it 'executes the given script and unwraps Watir elements' do
            @browser.load @dom_monitor_url
            source = Nokogiri::HTML(@browser.source).to_s

            expect(source).to eq(
                Nokogiri::HTML(subject.run_without_elements( 'return document.documentElement' ) ).to_s
            )

            expect(source).to eq(
                Nokogiri::HTML(subject.run_without_elements( 'return [document.documentElement]' ).first ).to_s
            )

            expect(source).to eq(
                Nokogiri::HTML(subject.run_without_elements( 'return { html: document.documentElement }' )['html'] ).to_s
            )
        end
    end
end
