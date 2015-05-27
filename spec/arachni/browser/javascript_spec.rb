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
    end

    subject { @browser.javascript }

    describe '.events_for' do
        it 'returns events for the given element' do
            described_class::EVENTS_PER_ELEMENT.each do |element, events|
                described_class.events_for( element ).should == described_class::GLOBAL_EVENTS | events
            end
        end
    end

    describe '.select_event_attributes' do
        it 'selects only attributes that are events' do
            attributes = {
                onclick:     'blah();',
                onmouseover: 'blah2();',
                id:          'my-id'
            }
            described_class.select_event_attributes( attributes ).should == {
                onclick:     'blah();',
                onmouseover: 'blah2();'
            }
        end
    end

    describe '#dom_monitor' do
        it 'provides access to the DOMMonitor javascript interface' do
            @browser.load "#{@taint_tracer_url}/debug"
            subject.dom_monitor.js_object.should end_with 'DOMMonitor'
        end
    end

    describe '#taint_tracer' do
        it 'provides access to the TaintTracer javascript interface' do
            @browser.load "#{@taint_tracer_url}/debug"
            subject.taint_tracer.js_object.should end_with 'TaintTracer'
        end
    end

    describe '#custom_code' do
        it 'injects the given code into the response' do
            subject.custom_code = 'window.has_custom_code = true'
            @browser.load "#{@taint_tracer_url}/debug"
            subject.run( 'return window.has_custom_code' ).should == true
        end
    end

    describe '#log_execution_flow_sink_stub' do
        it 'returns JS code for TaintTracer.log_execution_flow_sink()' do
            subject.log_execution_flow_sink_stub( 1, 2, 3 ).should ==
                "_#{subject.token}TaintTracer.log_execution_flow_sink(1, 2, 3)"
        end
    end

    describe '#log_data_flow_sink_stub' do
        it 'returns JS code for TaintTracer.log_data_flow_sink()' do
            subject.log_data_flow_sink_stub( 1, 2, 3 ).should ==
                "_#{subject.token}TaintTracer.log_data_flow_sink(1, 2, 3)"
        end
    end

    describe '#debug_stub' do
        it 'returns JS code for TaintTracer.debug()' do
            subject.debug_stub( 1, 2, 3 ).should ==
                "_#{subject.token}TaintTracer.debug(1, 2, 3)"
        end
    end

    describe '#supported?' do
        context 'when there is support for the Javascript environment' do
            it 'returns true' do
                @browser.load "#{@taint_tracer_url}/debug"
                subject.supported?.should be_true
            end
        end

        context 'when there is no support for the Javascript environment' do
            it 'returns false' do
                @browser.load "#{@taint_tracer_url}/without_javascript_support"
                subject.supported?.should be_false
            end
        end

        context 'when the resource is out-of-scope' do
            it 'returns false' do
                Arachni::Options.url = @taint_tracer_url
                @browser.load 'http://google.com/'
                subject.supported?.should be_false
            end
        end
    end

    describe '#log_execution_flow_sink_stub' do
        it 'returns JS code that calls JS\'s log_execution_flow_sink_stub()' do
            subject.log_execution_flow_sink_stub.should ==
                "_#{subject.token}TaintTracer.log_execution_flow_sink()"

            @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_execution_flow_sink_stub}"

            @browser.watir.form.submit
            subject.execution_flow_sinks.should be_any
            subject.execution_flow_sinks.first.data.should be_empty
        end
    end

    describe '#set_element_ids' do
        it 'sets custom ID attributes to elements with events but without ID' do
            @browser.load( @dom_monitor_url + 'set_element_ids' )

            as = @browser.watir.as

            as[0].name.should == '1'
            as[0].html.should_not include 'data-arachni-id'

            as[1].name.should == '2'
            as[1].html.should include 'data-arachni-id'

            as[2].name.should == '3'
            as[2].html.should_not include 'data-arachni-id'

            as[3].name.should == '4'
            as[3].html.should_not include 'data-arachni-id'
        end
    end

    describe '#dom_digest' do
        it 'returns a string digest of the current DOM tree' do
            @browser.load( @dom_monitor_url + 'digest' )
            subject.dom_digest.should == subject.dom_monitor.digest
        end
    end

    describe '#dom_elements_with_events' do
        context 'when using event attributes' do
            it 'returns information about all DOM elements along with their events' do
                @browser.load @dom_monitor_url + 'elements_with_events/attributes'

                subject.dom_elements_with_events.should == [
                    {
                        'tag_name' => 'body', 'events' => [], 'attributes' => {}
                    },
                    {
                        'tag_name'   => 'button',
                        'events'     => [
                            [:onclick, 'handler_1()']
                        ],
                        'attributes' => { 'onclick' => 'handler_1()', 'id' => 'my-button' }
                    },
                    {
                        'tag_name'   => 'button',
                        'events'     => [
                            [:onclick, 'handler_2()']
                        ],
                        'attributes' => { 'onclick' => 'handler_2()', 'id' => 'my-button2' }
                    },
                    {
                        'tag_name'   => 'button',
                        'events'     => [
                            [:onclick, 'handler_3()']
                        ],
                        'attributes' => { 'onclick' => 'handler_3()', 'id' => 'my-button3' }
                    }
                ]
            end
        end

        context 'when using event listeners' do
            it 'returns information about all DOM elements along with their events' do
                @browser.load @dom_monitor_url + 'elements_with_events/listeners'

                subject.dom_elements_with_events.should == [
                    {
                        'tag_name' => 'body', 'events' => [], 'attributes' => {}
                    },
                    {
                        'tag_name'   => 'button',
                        'events'     => [
                            [:click, 'function (my_button_click) {}'],
                            [:click, 'function (my_button_click2) {}'],
                            [:onmouseover, 'function (my_button_onmouseover) {}']
                        ],
                        'attributes' => { 'id' => 'my-button' } },
                    {
                        'tag_name'   => 'button',
                        'events'     => [
                            [:click, 'function (my_button2_click) {}']
                        ],
                        'attributes' => { 'id' => 'my-button2' } },
                    {
                        'tag_name'   => 'button',
                        'events'     => [],
                        'attributes' => { 'id' => 'my-button3' }
                    }
                ]
            end
        end
    end

    describe '#timeouts' do
        it 'keeps track of setTimeout() timers' do
            @browser.load( @dom_monitor_url + 'timeout-tracker' )
            subject.timeouts.should == subject.dom_monitor.timeouts
        end
    end

    describe '#intervals' do
        it 'keeps track of setInterval() timers' do
            @browser.load( @dom_monitor_url + 'interval-tracker' )
            subject.intervals.should == subject.dom_monitor.intervals
        end
    end

    describe '#debugging_data' do
        it 'returns debugging information' do
            @browser.load "#{@taint_tracer_url}/debug?input=#{subject.debug_stub(1)}"
            @browser.watir.form.submit
            subject.debugging_data.should == subject.taint_tracer.debugging_data
        end
    end

    describe '#execution_flow_sinks' do
        it 'returns sink data' do
            @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_execution_flow_sink_stub(1)}"
            @browser.watir.form.submit

            subject.execution_flow_sinks.should be_any
            subject.execution_flow_sinks.should == subject.taint_tracer.execution_flow_sinks
        end
    end

    describe '#data_flow_sinks' do
        it 'returns sink data' do
            @browser.javascript.taint = 'taint'
            @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_data_flow_sink_stub( @browser.javascript.taint, function: { name: 'blah' } )}"
            @browser.watir.form.submit

            sinks = subject.data_flow_sinks
            sinks.should be_any
            sinks.should == subject.taint_tracer.data_flow_sinks[@browser.javascript.taint]
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

            sink.should == sink2
        end

        it 'empties the sink' do
            @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_data_flow_sink_stub}"
            @browser.watir.form.submit

            subject.flush_data_flow_sinks
            subject.data_flow_sinks.should be_empty
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

            sink.should == sink2
        end

        it 'empties the sink' do
            @browser.load "#{@taint_tracer_url}/debug?input=#{subject.log_execution_flow_sink_stub}"
            @browser.watir.form.submit

            subject.flush_execution_flow_sinks
            subject.execution_flow_sinks.should be_empty
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
                        response.code.should == 200
                    end

                    it 'populates the given response body with its contents' do
                        response.body.should == body
                    end

                    it 'sets the correct Content-Type' do
                        response.headers.content_type.should == content_type
                    end

                    it 'sets the correct Content-Length' do
                        response.headers['content-length'].should == content_length
                    end

                    it 'returns true' do
                        subject.serve( request, response ).should be_true
                    end
                end
            end

            context 'other' do
                it 'returns false' do
                    request.url = 'stuff'
                    subject.serve( request, response ).should be_false
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

                it 'inject a TaintTracer.update_tracers() call before the code' do
                    injected.body.scan( /(.*)foo/m ).flatten.first.should include
                        "#{subject.taint_tracer.stub.function( :update_tracers )};"
                end

                it 'inject a DOMMonitor.update_trackers() call before the code' do
                    injected.body.scan( /(.*)foo/m ).flatten.first.should include
                        "#{subject.dom_monitor.stub.function( :update_trackers )};"
                end

                it 'inject a TaintTracer.update_tracers() call after the code' do
                    injected.body.scan( /foo(.*)/m ).flatten.first.should include
                        "#{subject.taint_tracer.stub.function( :update_tracers )};"
                end

                it 'inject a DOMMonitor.update_trackers() call after the code' do
                    injected.body.scan( /foo(.*)/m ).flatten.first.should include
                        "#{subject.dom_monitor.stub.function( :update_trackers )};"
                end

                it 'appends a semicolon and newline to the body' do
                    injected.body.should include "#{response.body};\n"
                end

                it 'updates the Content-Length' do
                    old_content_length = response.headers['content-length'].to_i

                    subject.inject( response )

                    new_content_length = response.headers['content-length'].to_i

                    new_content_length.should > old_content_length
                    new_content_length.should == response.body.bytesize
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

                it 'updates the Content-Length' do
                    old_content_length = response.headers['content-length'].to_i

                    subject.inject( response )

                    new_content_length = response.headers['content-length'].to_i

                    new_content_length.should > old_content_length
                    new_content_length.should == response.body.bytesize
                end

                context 'when the response does not already contain the JS code' do
                    it 'injects the system\'s JS interfaces in the response body' do
                        subject.inject( response )

                        %w(taint_tracer dom_monitor).each do |name|
                            src = "#{described_class::SCRIPT_BASE_URL}#{name}.js"
                            Nokogiri::HTML( response.body ).xpath( "//script[@src='#{src}']" ).should be_any
                        end
                    end

                    context 'when the response body contains script elements' do
                        before { response.body = '<script>// My code and stuff</script>' }

                        it 'injects taint tracer update calls at the top of the script' do
                            subject.inject( response )
                            Nokogiri::HTML(response.body).css('script')[-2].to_s.should ==
                                "<script>

                // Injected by #{described_class}
                _#{subject.token}TaintTracer.update_tracers();
                _#{subject.token}DOMMonitor.update_trackers();

// My code and stuff</script>"
                        end

                        it 'injects taint tracer update calls after the script' do
                            subject.inject( response )
                            Nokogiri::HTML(response.body).css('script')[-1].to_s.should ==
                                "<script type=\"text/javascript\">" +
                                "_#{subject.token}TaintTracer.update_tracers();" +
                                "_#{subject.token}DOMMonitor.update_trackers();" +
                                '</script>'
                        end
                    end
                end

                context 'when the response already contains the JS code' do
                    it 'updates the taints' do
                        subject.inject( response )

                        presponse = response.deep_clone
                        pintializer = subject.taint_tracer.stub.function( :initialize, [] )

                        subject.taint = [ 'taint1', 'taint2' ]
                        subject.inject( response )
                        intializer = subject.taint_tracer.stub.function( :initialize, subject.taint )

                        response.body.should == presponse.body.gsub( pintializer, intializer )
                    end

                    it 'updates the custom code' do
                        subject.custom_code = 'alert(1);'
                        subject.inject( response )

                        presponse = response.deep_clone
                        code      = subject.custom_code

                        subject.custom_code = 'alert(2);'
                        subject.inject( response )

                        response.body.should == presponse.body.gsub( code, subject.custom_code )
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

        context 'when the Content-Type does not include text/html' do
            it 'returns false'
        end

        context 'when the body does not include HTML identifiers such as' do
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
            Nokogiri::HTML(@browser.source).to_s.should ==
                Nokogiri::HTML(subject.run( 'return document.documentElement.innerHTML' ) ).to_s
        end
    end

    describe '#run_without_elements' do
        it 'executes the given script and unwraps Watir elements' do
            @browser.load @dom_monitor_url
            source = Nokogiri::HTML(@browser.source).to_s

            source.should ==
                Nokogiri::HTML(subject.run_without_elements( 'return document.documentElement' ) ).to_s

            source.should ==
                Nokogiri::HTML(subject.run_without_elements( 'return [document.documentElement]' ).first ).to_s

            source.should ==
                Nokogiri::HTML(subject.run_without_elements( 'return { html: document.documentElement }' )['html'] ).to_s
        end
    end
end
