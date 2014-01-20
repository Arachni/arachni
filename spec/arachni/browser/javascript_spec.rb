require 'spec_helper'

describe Arachni::Browser::Javascript do

    before( :all ) do
        @url = Arachni::Utilities.normalize_url( web_server_url_for( :javascript ) )
        @taint_tracer_url = Arachni::Utilities.normalize_url( web_server_url_for( :taint_tracer ) )
    end

    before( :each ) do
        @browser = Arachni::Browser.new
        @javascript = @browser.javascript
    end

    after( :each ) do
        Arachni::Options.reset
        Arachni::Framework.reset
        @browser.shutdown
    end

    describe '#dom_monitor' do
        it 'provides access to the DOMMonitor javascript interface' do
            @browser.load "#{@taint_tracer_url}/debug"
            @javascript.dom_monitor.js_object.should end_with 'DOMMonitor'
        end
    end

    describe '#taint_tracer' do
        it 'provides access to the TaintTracer javascript interface' do
            @browser.load "#{@taint_tracer_url}/debug"
            @javascript.taint_tracer.js_object.should end_with 'TaintTracer'
        end
    end

    describe '#supported?' do
        context 'when there is support for the Javascript environment' do
            it 'returns true' do
                @browser.load "#{@taint_tracer_url}/debug"
                @javascript.supported?.should be_true
            end
        end

        context 'when there is no support for the Javascript environment' do
            it 'returns false' do
                @browser.load "#{@taint_tracer_url}/without_javascript_support"
                @javascript.supported?.should be_false
            end
        end
    end

    describe '#log_sink_stub' do
        it 'returns JS code that calls JS\'s log_sink()' do
            @javascript.log_sink_stub.should == "_#{@javascript.token}TaintTracer.log_sink()"

            @browser.load "#{@taint_tracer_url}/debug?input=#{@javascript.log_sink_stub}"

            @browser.watir.form.submit
            @javascript.sink.should be_any
            @javascript.sink.first[:data].should be_empty
        end

        context 'when an argument is passed' do
            it 'converts it to JSON' do
                [1, true].each do |arg|
                    @browser.load "#{@taint_tracer_url}/debug?input=#{@javascript.log_sink_stub( arg )}"
                    @browser.watir.form.submit
                    @javascript.sink.first[:data].should == [arg]
                end
            end
        end
    end

    describe '#timeouts' do
        it 'keeps track of setTimeout() timers' do
            @browser.load( @url + 'timeout-tracker' )

            @javascript.timeouts.should == [
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
    end

    describe '#intervals' do
        it 'keeps track of setInterval() timers' do
            @browser.load( @url + 'interval-tracker' )
            @browser.javascript.intervals.should == [
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
    end

    describe '#debugging_data' do
        it 'returns debugging information' do
            @browser.load "#{@taint_tracer_url}/debug?input=#{@javascript.debug_stub(1)}"
            @browser.watir.form.submit
            @javascript.debugging_data.should == @javascript.taint_tracer.debugging_data
        end
    end

    describe '#sink' do
        it 'returns sink data' do
            @browser.load "#{@taint_tracer_url}/debug?input=#{@javascript.log_sink_stub(1)}"
            @browser.watir.form.submit
            @javascript.sink.should == @javascript.taint_tracer.sink
        end
    end

    describe '#flush_sink' do
        it 'returns sink data' do
            @browser.load "#{@taint_tracer_url}/debug?input=#{@javascript.log_sink_stub(1)}"
            @browser.watir.form.submit

            sink = @javascript.flush_sink
            sink[0][:trace][1][:arguments][0].delete( 'timeStamp' )

            @browser.load "#{@taint_tracer_url}/debug?input=#{@javascript.log_sink_stub(1)}"
            @browser.watir.form.submit

            sink2 = @javascript.taint_tracer.sink
            sink2[0][:trace][1][:arguments][0].delete( 'timeStamp' )

            sink.should == sink2
        end

        it 'empties the sink' do
            @browser.load "#{@taint_tracer_url}/debug?input=#{@javascript.log_sink_stub}"
            @browser.watir.form.submit
            @javascript.flush_sink
            @javascript.sink.should be_empty
        end
    end

    describe '#serve' do
        context 'when the request URL is' do
            %W(dom_monitor.js taint_tracer.js).each do |filename|
                url          = "#{described_class::SCRIPT_BASE_URL}#{filename}"
                let(:url) { url }
                let(:content_type) { 'text/javascript' }
                let(:body) do
                    IO.read( "#{described_class::SCRIPT_LIBRARY}#{filename}" ).
                        gsub( '_token', "_#{@javascript.token}" )
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
                    before(:each){ @javascript.serve( request, response ) }

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
                        @javascript.serve( request, response ).should be_true
                    end
                end
            end

            context 'other' do
                it 'returns false' do
                    request.url = 'stuff'
                    @javascript.serve( request, response ).should be_false
                end
            end
        end
    end

    describe '#inject' do
        let(:response) { Arachni::HTTP::Response.new( url: @url ) }

        context 'when the response does not already contain the JS code' do
            it 'injects the system\'s JS interfaces in the response body' do
                @javascript.inject( response )
                @browser.load response

                @javascript.taint_tracer.initialized.should be_true
                @javascript.dom_monitor.initialized.should be_true
            end

            it 'updates the Content-Length' do
                old_content_length = response.headers['content-length'].to_i

                @javascript.inject( response )

                new_content_length = response.headers['content-length'].to_i

                new_content_length.should > old_content_length
                new_content_length.should == response.body.bytesize
            end

            it 'returns true' do
                @javascript.inject( response ).should be_true
            end

            context 'when the response body contains script elements' do
                before { response.body = '<script> // My code and stuff </script>' }

                context 'and a taint has been configured' do
                    before { @javascript.taint = 'my_taint' }

                    it 'injects taint tracer update calls at the top of the script' do
                        @javascript.inject( response )
                        Nokogiri::HTML(response.body).css('script')[-2].to_s.should ==
                            "<script>
_#{@javascript.token}TaintTracer.update_tracers(); // Injected by Arachni::Browser::Javascript
 // My code and stuff </script>"
                    end

                    it 'injects taint tracer update calls after the script' do
                        @javascript.inject( response )
                        @javascript.inject( response )
                        Nokogiri::HTML(response.body).css('script')[-1].to_s.should ==
                            "<script type=\"text/javascript\">_#{@javascript.token}TaintTracer.update_tracers()</script>"
                    end
                end
            end
        end

        context 'when the response already contains the JS code' do
            it 'skips it' do
                original_response = response.deep_clone
                @javascript.inject( response )
                original_response.should_not == response

                updated_response = response.deep_clone
                @javascript.inject( response )
                updated_response.should == response
            end

            it 'returns false' do
                @javascript.inject( response ).should be_true
                @javascript.inject( response ).should be_false
            end
        end
    end

    describe '#run' do
        it 'executes the given script under the browser\'s context' do
            @browser.load @url
            Nokogiri::HTML(@browser.source).to_s.should ==
                Nokogiri::HTML(@javascript.run( 'return document.documentElement.innerHTML' ) ).to_s
        end
    end

end
