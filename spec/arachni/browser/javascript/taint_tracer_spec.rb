require 'spec_helper'

describe Arachni::Browser::Javascript::TaintTracer do

    before( :all ) do
        @url = Arachni::Utilities.normalize_url( web_server_url_for( :taint_tracer ) )
    end

    before( :each ) do
        @browser      = Arachni::Browser.new
        @javascript   = @browser.javascript
        @browser.load @url
        @taint_tracer = described_class.new( @javascript )
    end

    def load_with_taint( path )
        load "#{path}?taint=#{@javascript.taint}"
    end

    def load( path )
        @browser.load "#{@url}#{path}", take_snapshot: false
    end

    subject { @taint_tracer }
    let(:taint) { 'my_taint' }

    after( :each ) do
        @browser.shutdown
    end

    describe '#initialized' do
        it 'returns true' do
            subject.initialized.should be_true
        end
    end

    describe '#class' do
        it "returns #{described_class}" do
            subject.class.should == described_class
        end
    end

    it 'is aliased to _token_taint_tracer' do
        load "debug?input=_#{@javascript.token}_taint_tracer.log_execution_flow_sink()"
        @browser.watir.form.submit
        subject.execution_flow_sink.should be_any
    end

    it 'is aliased to _tokentainttracer' do
        load "debug?input=_#{@javascript.token}tainttracer.log_execution_flow_sink()"
        @browser.watir.form.submit
        subject.execution_flow_sink.should be_any
    end

    describe '#taint=' do
        it 'sets the taint to be traced' do
            subject.taint = taint
            subject.taint.should == taint
        end

        context 'when tainted data pass through' do
            before { @javascript.taint = @browser.generate_token }

            context 'user-defined global functions' do
                it 'logs it' do
                    load_with_taint 'data_trace/user-defined-global-functions'

                    sink = subject.data_flow_sinks
                    sink.size.should == 1

                    entry = sink[0]
                    entry.object.should == 'DOMWindow'
                    entry.function.name.should == 'process'
                    entry.function.source.should start_with 'function process'
                    entry.function.arguments.should == [
                        {
                            'my_data' => 'blah',
                            'input'   => @javascript.taint
                        }
                    ]
                    entry.tainted_value.should == @javascript.taint
                    entry.taint.should == @javascript.taint
                    @browser.source.split("\n")[entry.trace[0].line-1].should include 'process('
                end
            end

            context 'window' do
                %w(eval encodeURIComponent decodeURIComponent encodeURI decodeURI).each do |function|
                    context ".#{function}" do
                        it 'logs it' do
                            load_with_taint "data_trace/window.#{function}"

                            sink = subject.data_flow_sinks
                            sink.size.should == 1

                            entry = sink[0]
                            entry.object.should == 'DOMWindow'
                            entry.function.name.should == function
                            entry.function.source.should start_with "function #{function}"
                            entry.function.arguments.should == [ @javascript.taint ]
                            entry.tainted_value.should == @javascript.taint
                            entry.taint.should == @javascript.taint
                            @browser.source.split("\n")[entry.trace[0].line].should include "#{function}("
                        end
                    end
                end
            end

            context 'XMLHttpRequest' do
                context '.open' do
                    it 'logs it' do
                        load_with_taint 'data_trace/XMLHttpRequest.open'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'XMLHttpRequestPrototype'
                        entry.function.name.should == 'open'
                        entry.function.arguments.should == [
                            'GET', "/?taint=#{@javascript.taint}", true
                        ]
                        entry.tainted_value.should == "/?taint=#{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'open('
                        trace.url.should == @browser.url
                    end
                end

                context '.send' do
                    it 'logs it' do
                        load_with_taint 'data_trace/XMLHttpRequest.send'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'XMLHttpRequestPrototype'
                        entry.function.name.should == 'send'
                        entry.function.arguments.should == [ "taint=#{@javascript.taint}" ]
                        entry.tainted_value.should == "taint=#{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'send('
                        trace.url.should == @browser.url
                    end
                end

                context '.setRequestHeader' do
                    it 'logs it' do
                        load_with_taint 'data_trace/XMLHttpRequest.setRequestHeader'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'XMLHttpRequestPrototype'
                        entry.function.name.should == 'setRequestHeader'
                        entry.function.arguments.should == [ 'X-My-Header', "stuff-#{@javascript.taint}" ]
                        entry.tainted_value.should == "stuff-#{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'setRequestHeader('
                        trace.url.should == @browser.url
                    end
                end
            end

            context 'AngularJS' do
                context '.element' do
                    it 'logs it' do
                        load_with_taint 'data_trace/AngularJS.element'

                        sink = subject.data_flow_sinks
                        sink.size.should == 2

                        entry = sink[1]
                        entry.object.should == 'angular'
                        entry.function.name.should == 'JQLite'
                        entry.function.arguments.should == ["<div>Stuff #{@javascript.taint}</div>"]
                        entry.tainted_value.should == "<div>Stuff #{@javascript.taint}</div>"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'angular.element('
                        trace.url.should == @browser.url
                    end
                end

                context '$http' do
                    context '.delete' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/$http.delete'

                            sink = subject.data_flow_sinks
                            sink.size.should == 4

                            entry = sink[1]
                            entry.object.should == 'angular.$http'
                            entry.function.name.should == 'delete'
                            entry.function.arguments.should == [ "/#{@javascript.taint}" ]
                            entry.tainted_value.should == "/#{@javascript.taint}"
                            entry.taint.should == @javascript.taint
                            entry.trace[0].url.should == @browser.url

                            entry = sink[3]
                            entry.object.should == 'XMLHttpRequestPrototype'
                            entry.function.name.should == 'open'
                            entry.function.arguments.should == [
                                'DELETE', "/#{@javascript.taint}", true
                            ]
                            entry.tainted_value.should == "/#{@javascript.taint}"
                            entry.taint.should == @javascript.taint
                            entry.trace[0].url.should == "#{@url}angular.js"
                        end
                    end

                    context '.head' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/$http.head'

                            sink = subject.data_flow_sinks
                            sink.size.should == 4

                            entry = sink[1]
                            entry.object.should == 'angular.$http'
                            entry.function.name.should == 'head'
                            entry.function.arguments.should == [ "/#{@javascript.taint}" ]
                            entry.tainted_value.should == "/#{@javascript.taint}"
                            entry.taint.should == @javascript.taint
                            entry.trace[0].url.should == @browser.url

                            entry = sink[3]
                            entry.object.should == 'XMLHttpRequestPrototype'
                            entry.function.name.should == 'open'
                            entry.function.arguments.should == [
                                'HEAD', "/#{@javascript.taint}", true
                            ]
                            entry.tainted_value.should == "/#{@javascript.taint}"
                            entry.taint.should == @javascript.taint
                            entry.trace[0].url.should == "#{@url}angular.js"
                        end
                    end

                    context '.jsonp' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/$http.jsonp'

                            sink = subject.data_flow_sinks
                            sink.size.should == 3

                            entry = sink[1]
                            entry.object.should == 'angular.$http'
                            entry.function.name.should == 'jsonp'
                            entry.function.arguments.should == [ "/jsonp-#{@javascript.taint}" ]
                            entry.tainted_value.should == "/jsonp-#{@javascript.taint}"
                            entry.taint.should == @javascript.taint
                            entry.trace[0].url.should == @browser.url

                            entry = sink[2]
                            entry.object.should == 'ElementPrototype'
                            entry.function.name.should == 'setAttribute'
                            entry.function.arguments.should == [
                                'href', "/jsonp-#{@javascript.taint}"
                            ]
                            entry.tainted_value.should == "/jsonp-#{@javascript.taint}"
                            entry.taint.should == @javascript.taint
                            entry.trace[0].url.should == "#{@url}angular.js"
                        end
                    end

                    context '.put' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/$http.put'

                            sink = subject.data_flow_sinks
                            sink.size.should == 3

                            entry = sink[1]
                            entry.object.should == 'angular.$http'
                            entry.function.name.should == 'put'
                            entry.function.arguments.should == [
                                '/', "Stuff #{@javascript.taint}"
                            ]
                            entry.tainted_value.should == "Stuff #{@javascript.taint}"
                            entry.taint.should == @javascript.taint
                            entry.trace[0].url.should == @browser.url

                            entry = sink[2]
                            entry.object.should == 'XMLHttpRequestPrototype'
                            entry.function.name.should == 'send'
                            entry.function.arguments.should == [ "Stuff #{@javascript.taint}" ]
                            entry.tainted_value.should == "Stuff #{@javascript.taint}"
                            entry.taint.should == @javascript.taint
                            entry.trace[0].url.should == "#{@url}angular.js"
                        end
                    end

                    context '.get' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/$http.get'

                            sink = subject.data_flow_sinks
                            sink.size.should == 4

                            entry = sink[1]
                            entry.object.should == 'angular.$http'
                            entry.function.name.should == 'get'
                            entry.function.arguments.should == [ "/#{@javascript.taint}" ]
                            entry.tainted_value.should == "/#{@javascript.taint}"
                            entry.taint.should == @javascript.taint
                            entry.trace[0].url.should == @browser.url

                            entry = sink[3]
                            entry.object.should == 'XMLHttpRequestPrototype'
                            entry.function.name.should == 'open'
                            entry.function.arguments.should == [
                                'GET', "/#{@javascript.taint}", true
                            ]
                            entry.tainted_value.should == "/#{@javascript.taint}"
                            entry.taint.should == @javascript.taint
                            entry.trace[0].url.should == "#{@url}angular.js"
                        end
                    end

                    context '.post' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/$http.post'

                            sink = subject.data_flow_sinks
                            sink.size.should == 4

                            entry = sink[1]
                            entry.object.should == 'angular.$http'
                            entry.function.name.should == 'post'
                            entry.function.arguments.should == [
                                '/', '',
                                {
                                    'params' => {
                                        'stuff' => "Stuff #{@javascript.taint}"
                                    },
                                    'method' => 'post',
                                    'url'    => '/',
                                    'data'   => ''
                                }
                            ]
                            entry.tainted_value.should == "Stuff #{@javascript.taint}"
                            entry.taint.should == @javascript.taint
                            entry.trace[0].url.should == @browser.url

                            entry = sink[3]
                            entry.object.should == 'XMLHttpRequestPrototype'
                            entry.function.name.should == 'open'
                            entry.function.arguments.should == [
                                'POST', "/?stuff=Stuff+#{@javascript.taint}", true
                            ]
                            entry.tainted_value.should == "/?stuff=Stuff+#{@javascript.taint}"
                            entry.taint.should == @javascript.taint
                            entry.trace[0].url.should == "#{@url}angular.js"
                        end
                    end
                end

                context 'ngRoute' do
                    context 'template' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/ngRoute/'

                            sink = subject.data_flow_sinks
                            sink.size.should == 6

                            # ngRoute module first schedules an HTTP request to grab
                            # the template from the given 'templateUrl'...
                            entry = sink[4]
                            entry.object.should == 'XMLHttpRequestPrototype'
                            entry.function.name.should == 'open'
                            entry.function.arguments.should == [
                                'GET', "template.html?taint=#{@javascript.taint}", true
                            ]
                            entry.tainted_value.should == "template.html?taint=#{@javascript.taint}"
                            entry.taint.should == @javascript.taint
                            entry.trace[0].url.should == "#{@url}angular.js"

                            #... and then updates the app with the (tainted) template content.
                            entry = sink[5]
                            entry.object.should == 'angular.element'
                            entry.function.name.should == 'html'
                            entry.function.arguments.should == ["Blah blah blah #{@javascript.taint}\n"]
                            entry.tainted_value.should == "Blah blah blah #{@javascript.taint}\n"
                            entry.taint.should == @javascript.taint
                            entry.trace[0].url.should == "#{@url}angular-route.js"
                        end
                    end
                end

                context 'jqLite' do
                    context '.html' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/jqLite.html'

                            sink = subject.data_flow_sinks
                            sink.size.should == 2

                            entry = sink[1]
                            entry.object.should == 'angular.element'
                            entry.function.name.should == 'html'
                            entry.function.arguments.should == ["Stuff #{@javascript.taint}"]
                            entry.tainted_value.should == "Stuff #{@javascript.taint}"
                            entry.taint.should == @javascript.taint

                            trace = entry.trace[0]
                            @browser.source.split("\n")[trace.line-1].should include 'html('
                            trace.url.should == @browser.url
                        end
                    end

                    context '.text' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/jqLite.text'

                            sink = subject.data_flow_sinks
                            sink.size.should == 2

                            entry = sink[1]
                            entry.object.should == 'angular.element'
                            entry.function.name.should == 'text'
                            entry.function.arguments.should == ["Stuff #{@javascript.taint}"]
                            entry.tainted_value.should == "Stuff #{@javascript.taint}"
                            entry.taint.should == @javascript.taint

                            trace = entry.trace[0]
                            @browser.source.split("\n")[trace.line-1].should include 'text('
                            trace.url.should == @browser.url
                        end
                    end

                    context '.append' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/jqLite.append'

                            sink = subject.data_flow_sinks
                            sink.size.should == 2

                            entry = sink[1]
                            entry.object.should == 'angular.element'
                            entry.function.name.should == 'append'
                            entry.function.arguments.should == ["Stuff #{@javascript.taint}"]
                            entry.tainted_value.should == "Stuff #{@javascript.taint}"
                            entry.taint.should == @javascript.taint

                            trace = entry.trace[0]
                            @browser.source.split("\n")[trace.line].should include 'append('
                            trace.url.should == @browser.url
                        end
                    end

                    context '.prepend' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/jqLite.prepend'

                            sink = subject.data_flow_sinks
                            sink.size.should == 2

                            entry = sink[1]
                            entry.object.should == 'angular.element'
                            entry.function.name.should == 'prepend'
                            entry.function.arguments.should == ["Stuff #{@javascript.taint}"]
                            entry.tainted_value.should == "Stuff #{@javascript.taint}"
                            entry.taint.should == @javascript.taint

                            trace = entry.trace[0]
                            @browser.source.split("\n")[trace.line].should include 'prepend('
                            trace.url.should == @browser.url
                        end
                    end

                    context '.prop' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/jqLite.prop'

                            sink = subject.data_flow_sinks
                            sink.size.should == 2

                            entry = sink[1]
                            entry.object.should == 'angular.element'
                            entry.function.name.should == 'prop'
                            entry.function.arguments.should == [ 'stuff', "Stuff #{@javascript.taint}"]
                            entry.tainted_value.should == "Stuff #{@javascript.taint}"
                            entry.taint.should == @javascript.taint

                            trace = entry.trace[0]
                            @browser.source.split("\n")[trace.line].should include 'prop('
                            trace.url.should == @browser.url
                        end
                    end

                    context '.replaceWith' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/jqLite.replaceWith'

                            sink = subject.data_flow_sinks
                            sink.size.should == 2

                            entry = sink[1]
                            entry.object.should == 'angular.element'
                            entry.function.name.should == 'replaceWith'
                            entry.function.arguments.should == [ "Stuff #{@javascript.taint}"]
                            entry.tainted_value.should == "Stuff #{@javascript.taint}"
                            entry.taint.should == @javascript.taint

                            trace = entry.trace[0]
                            @browser.source.split("\n")[trace.line-1].should include 'replaceWith('
                            trace.url.should == @browser.url
                        end
                    end

                    context '.val' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/jqLite.val'

                            sink = subject.data_flow_sinks
                            sink.size.should == 2

                            entry = sink[1]
                            entry.object.should == 'angular.element'
                            entry.function.name.should == 'val'
                            entry.function.arguments.should == [ "Stuff #{@javascript.taint}"]
                            entry.tainted_value.should == "Stuff #{@javascript.taint}"
                            entry.taint.should == @javascript.taint

                            trace = entry.trace[0]
                            @browser.source.split("\n")[trace.line].should include 'val('
                            trace.url.should == @browser.url
                        end
                    end
                end
            end

            context 'jQuery' do
                context '.ajax' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.ajax'

                        sink = subject.data_flow_sinks
                        sink.size.should == 3

                        entry = sink[0]
                        entry.object.should == 'jQuery'
                        entry.function.name.should == 'ajax'
                        entry.function.arguments.should == [
                            {
                                'url'  => '/',
                                'data' => {
                                    'stuff' => "mystuff #{@javascript.taint}"
                                }
                            }
                        ]
                        entry.tainted_value.should == "mystuff #{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'ajax('
                        trace.url.should == @browser.url
                    end
                end

                context '.get' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.get'

                        sink = subject.data_flow_sinks
                        sink.size.should == 4

                        entry = sink[0]
                        entry.object.should == 'jQuery'
                        entry.function.name.should == 'get'
                        entry.function.arguments.should == [
                            '/',
                            { 'stuff' => "mystuff #{@javascript.taint}" }
                        ]
                        entry.tainted_value.should == "mystuff #{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'get('
                        trace.url.should == @browser.url
                    end
                end

                context '.post' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.post'

                        sink = subject.data_flow_sinks
                        sink.size.should == 3

                        entry = sink[0]
                        entry.object.should == 'jQuery'
                        entry.function.name.should == 'post'
                        entry.function.arguments.should == [ "/#{@javascript.taint}" ]
                        entry.tainted_value.should == "/#{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'post('
                        trace.url.should == @browser.url
                    end
                end

                context '.load' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.load'

                        sink = subject.data_flow_sinks
                        sink.size.should == 3

                        entry = sink[0]
                        entry.object.should == 'jQuery'
                        entry.function.name.should == 'load'
                        entry.function.arguments.should == [ "/#{@javascript.taint}" ]
                        entry.tainted_value.should == "/#{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'load('
                        trace.url.should == @browser.url
                    end
                end

                context '.html' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.html'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'jQuery'
                        entry.function.name.should == 'html'
                        entry.function.arguments.should == ["Stuff #{@javascript.taint}"]
                        entry.tainted_value.should == "Stuff #{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line-1].should include 'html('
                        trace.url.should == @browser.url
                    end
                end

                context '.text' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.text'

                        sink = subject.data_flow_sinks
                        sink.size.should == 2

                        entry = sink[0]
                        entry.object.should == 'jQuery'
                        entry.function.name.should == 'text'
                        entry.function.arguments.should == ["Stuff #{@javascript.taint}"]
                        entry.tainted_value.should == "Stuff #{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line-1].should include 'text('
                        trace.url.should == @browser.url
                    end
                end

                context '.append' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.append'

                        sink = subject.data_flow_sinks
                        sink.size.should == 2

                        entry = sink[0]
                        entry.object.should == 'jQuery'
                        entry.function.name.should == 'append'
                        entry.function.arguments.should == ["Stuff #{@javascript.taint}"]
                        entry.tainted_value.should == "Stuff #{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'append('
                        trace.url.should == @browser.url
                    end
                end

                context '.prepend' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.prepend'

                        sink = subject.data_flow_sinks
                        sink.size.should == 2

                        entry = sink[0]
                        entry.object.should == 'jQuery'
                        entry.function.name.should == 'prepend'
                        entry.function.arguments.should == ["Stuff #{@javascript.taint}"]
                        entry.tainted_value.should == "Stuff #{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'prepend('
                        trace.url.should == @browser.url
                    end
                end

                context '.before' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.before'

                        sink = subject.data_flow_sinks
                        sink.size.should == 2

                        entry = sink[0]
                        entry.object.should == 'jQuery'
                        entry.function.name.should == 'before'
                        entry.function.arguments.should == ["Stuff #{@javascript.taint}"]
                        entry.tainted_value.should == "Stuff #{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'before('
                        trace.url.should == @browser.url
                    end
                end

                context '.prop' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.prop'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'jQuery'
                        entry.function.name.should == 'prop'
                        entry.function.arguments.should == [ 'stuff', "Stuff #{@javascript.taint}"]
                        entry.tainted_value.should == "Stuff #{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'prop('
                        trace.url.should == @browser.url
                    end
                end

                context '.replaceWith' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.replaceWith'

                        sink = subject.data_flow_sinks
                        sink.size.should == 2

                        entry = sink[0]
                        entry.object.should == 'jQuery'
                        entry.function.name.should == 'replaceWith'
                        entry.function.arguments.should == [ "Stuff #{@javascript.taint}"]
                        entry.tainted_value.should == "Stuff #{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line-1].should include 'replaceWith('
                        trace.url.should == @browser.url
                    end
                end

                context '.val' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.val'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'jQuery'
                        entry.function.name.should == 'val'
                        entry.function.arguments.should == [ "Stuff #{@javascript.taint}"]
                        entry.tainted_value.should == "Stuff #{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'val('
                        trace.url.should == @browser.url
                    end
                end
            end

            context 'String' do
                context '.replace' do
                    it 'logs it' do
                        load_with_taint 'data_trace/String.replace'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'String'
                        entry.function.name.should == 'replace'
                        entry.function.source.should start_with 'function replace'
                        entry.function.arguments.should == [
                            'my', @javascript.taint
                        ]
                        entry.tainted_value.should == @javascript.taint
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'replace('
                        trace.url.should == @browser.url
                    end
                end

                context '.concat' do
                    it 'logs it' do
                        load_with_taint 'data_trace/String.concat'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'String'
                        entry.function.name.should == 'concat'
                        entry.function.source.should start_with 'function concat'
                        entry.function.arguments.should == [ "stuff #{@javascript.taint}" ]
                        entry.tainted_value.should == "stuff #{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'concat('
                        trace.url.should == @browser.url
                    end
                end
            end

            context 'HTMLElement' do
                context '.insertAdjacentHTML' do
                    it 'logs it' do
                        load_with_taint 'data_trace/HTMLElement.insertAdjacentHTML'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'HTMLElementPrototype'
                        entry.function.name.should == 'insertAdjacentHTML'
                        entry.function.source.should start_with 'function insertAdjacentHTML'
                        entry.function.arguments.should == [
                            'AfterBegin', "stuff #{@javascript.taint} more stuff"
                        ]
                        entry.tainted_value.should == "stuff #{@javascript.taint} more stuff"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'insertAdjacentHTML('
                        trace.url.should == @browser.url
                    end
                end
            end

            context 'Element' do
                context '.setAttribute' do
                    it 'logs it' do
                        load_with_taint 'data_trace/Element.setAttribute'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'ElementPrototype'
                        entry.function.name.should == 'setAttribute'
                        entry.function.source.should start_with 'function setAttribute'
                        entry.function.arguments.should == [
                            'my-attribute', "stuff #{@javascript.taint} more stuff"
                        ]
                        entry.tainted_value.should == "stuff #{@javascript.taint} more stuff"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'setAttribute('
                        trace.url.should == @browser.url
                    end
                end
            end

            context 'Document' do
                context '.createTextNode' do
                    it 'logs it' do
                        load_with_taint 'data_trace/Document.createTextNode'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'DocumentPrototype'
                        entry.function.name.should == 'createTextNode'
                        entry.function.source.should start_with 'function createTextNode'
                        entry.function.arguments.should == [ "node #{@javascript.taint}" ]
                        entry.tainted_value.should == "node #{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'document.createTextNode('
                        trace.url.should == @browser.url
                    end
                end
            end

            context 'CharacterData' do
                context '.insertData' do
                    it 'logs it' do
                        load_with_taint 'data_trace/CharacterData.insertData'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'CharacterDataPrototype'
                        entry.function.name.should == 'insertData'
                        entry.function.source.should start_with 'function insertData'
                        entry.function.arguments.should == [ "Stuff #{@javascript.taint}" ]
                        entry.tainted_value.should == "Stuff #{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'insertData('
                        trace.url.should == @browser.url
                    end
                end

                context '.appendData' do
                    it 'logs it' do
                        load_with_taint 'data_trace/CharacterData.appendData'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'CharacterDataPrototype'
                        entry.function.name.should == 'appendData'
                        entry.function.source.should start_with 'function appendData'
                        entry.function.arguments.should == [ "Stuff #{@javascript.taint}" ]
                        entry.tainted_value.should == "Stuff #{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'appendData('
                        trace.url.should == @browser.url
                    end
                end

                context '.replaceData' do
                    it 'logs it' do
                        load_with_taint 'data_trace/CharacterData.replaceData'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'CharacterDataPrototype'
                        entry.function.name.should == 'replaceData'
                        entry.function.source.should start_with 'function replaceData'
                        entry.function.arguments.should == [ 0, 0, "Stuff #{@javascript.taint}" ]
                        entry.tainted_value.should == "Stuff #{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'replaceData('
                        trace.url.should == @browser.url
                    end
                end
            end

            context 'Text' do
                context '.replaceWholeText' do
                    it 'logs it' do
                        load_with_taint 'data_trace/Text.replaceWholeText'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'TextPrototype'
                        entry.function.name.should == 'replaceWholeText'
                        entry.function.source.should start_with 'function replaceWholeText'
                        entry.function.arguments.should == [ "Stuff #{@javascript.taint}" ]
                        entry.tainted_value.should == "Stuff #{@javascript.taint}"
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'replaceWholeText('
                        trace.url.should == @browser.url
                    end
                end
            end

            context 'HTMLDocument' do
                context '.write' do
                    it 'logs it' do
                        load_with_taint 'data_trace/HTMLDocument.write'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'HTMLDocumentPrototype'
                        entry.function.name.should == 'write'
                        entry.function.source.should start_with 'function write'
                        entry.function.arguments.should == [
                            "Stuff here blah #{@javascript.taint} more stuff nlahblah..."
                        ]
                        entry.tainted_value.should ==
                            "Stuff here blah #{@javascript.taint} more stuff nlahblah..."
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'document.write('
                        trace.url.should == @browser.url
                    end
                end

                context '.writeln' do
                    it 'logs it' do
                        load_with_taint 'data_trace/HTMLDocument.writeln'

                        sink = subject.data_flow_sinks
                        sink.size.should == 1

                        entry = sink[0]
                        entry.object.should == 'HTMLDocumentPrototype'
                        entry.function.name.should == 'writeln'
                        entry.function.source.should start_with 'function writeln'
                        entry.function.arguments.should == [
                            "Stuff here blah #{@javascript.taint} more stuff nlahblah..."
                        ]
                        entry.tainted_value.should ==
                            "Stuff here blah #{@javascript.taint} more stuff nlahblah..."
                        entry.taint.should == @javascript.taint

                        trace = entry.trace[0]
                        @browser.source.split("\n")[trace.line].should include 'document.writeln('
                        trace.url.should == @browser.url
                    end
                end
            end
        end
    end

    describe '#taint' do
        context 'by default' do
            it 'returns nil' do
                subject.taint.should be_nil
            end
        end
    end

    describe '#enable_debugging=' do
        it 'sets the debugging flag' do
            subject.enable_debugging = false
            subject.enable_debugging.should == false
        end
    end

    describe '#enable_debugging' do
        context 'by default' do
            it 'returns true' do
                subject.enable_debugging.should == true
            end
        end
    end

    describe '#execution_flow_sink' do
        it 'returns sink data' do
            load "debug?input=#{subject.stub.function(:log_execution_flow_sink)}"
            @browser.watir.form.submit
            subject.execution_flow_sink.should be_any
        end

        context 'by default' do
            it 'returns []' do
                subject.execution_flow_sink.should == []
            end
        end
    end

    describe '#data_flow_sinks' do
        it 'returns sink data' do
            load "debug?input=#{subject.stub.function(:log_data_flow_sink, { function: 'blah' })}"
            @browser.watir.form.submit
            subject.data_flow_sinks.should be_any
        end

        context 'by default' do
            it 'returns []' do
                subject.data_flow_sinks.should == []
            end
        end
    end

    describe '#flush_data_flow_sinks' do
        it 'returns sink data' do
            load "debug?input=#{subject.stub.function(:log_data_flow_sink, { function: { name: 'blah' } })}"
            @browser.watir.form.submit
            sink_data = subject.flush_data_flow_sinks

            first_entry = sink_data.first
            sink_data.should == [first_entry]

            first_entry.function.name.should == 'blah'
            first_entry.trace.size.should == 2

            first_entry.trace[0].function.name.should == 'onClick'
            first_entry.trace[0].function.source.should start_with 'function onClick'
            @browser.source.split("\n")[first_entry.trace[0].line].should include 'log_data_flow_sink'
            first_entry.trace[0].function.arguments.should == %w(some-arg arguments-arg here-arg)

            first_entry.trace[1].function.name.should == 'onsubmit'
            first_entry.trace[1].function.source.should start_with 'function onsubmit'
            @browser.source.split("\n")[first_entry.trace[1].line].should include 'onsubmit'
            first_entry.trace[1].function.arguments.size.should == 1

            event = first_entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            event['target'].should == form
            event['srcElement'].should == form
            event['type'].should == 'submit'
        end

        it 'empties the sink' do
            load "debug?input=#{subject.stub.function(:log_data_flow_sink, { function: { name: 'blah' } })}"
            @browser.watir.form.submit
            subject.flush_data_flow_sinks
            @javascript.flush_data_flow_sinks.should be_empty
        end
    end

    describe '#flush_execution_flow_sink' do
        it 'returns sink data' do
            load "debug?input=#{subject.stub.function(:log_execution_flow_sink, 1)}"
            @browser.watir.form.submit
            sink_data = subject.flush_execution_flow_sink

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
            @browser.source.split("\n")[first_entry.trace[1].line].should include 'onsubmit'
            first_entry.trace[1].function.arguments.size.should == 1

            event = first_entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            event['target'].should == form
            event['srcElement'].should == form
            event['type'].should == 'submit'
        end

        it 'empties the sink' do
            load "debug?input=#{subject.stub.function(:log_data_flow_sink)}"
            @browser.watir.form.submit
            subject.flush_execution_flow_sink
            @javascript.flush_execution_flow_sink.should be_empty
        end
    end

    describe '#log_execution_flow_sink' do
        it 'logs a sink' do
            load "debug?input=#{subject.stub.function(:log_execution_flow_sink, 1)}"
            @browser.watir.form.submit
            sink_data = subject.execution_flow_sink

            first_entry = sink_data.first
            sink_data.should == [first_entry]

            first_entry.data.should == [1]
            first_entry.trace.size.should == 2

            first_entry.trace[0].function.name.should  == 'onClick'
            first_entry.trace[0].function.source.should start_with 'function onClick'
            @browser.source.split("\n")[first_entry.trace[0].line].should include 'log_execution_flow_sink(1)'
            first_entry.trace[0].function.arguments.should == %w(some-arg arguments-arg here-arg)

            first_entry.trace[1].function.name.should == 'onsubmit'
            first_entry.trace[1].function.source.should start_with 'function onsubmit'
            @browser.source.split("\n")[first_entry.trace[1].line].should include 'onsubmit'
            first_entry.trace[1].function.arguments.size.should == 1

            event = first_entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            event['target'].should == form
            event['srcElement'].should == form
            event['type'].should == 'submit'
        end
    end

    describe '#log_data_flow_sink' do
        it 'logs a sink' do
            load "debug?input=#{subject.stub.function(:log_data_flow_sink, { function: { name: 'blah' } })}"
            @browser.watir.form.submit
            sink_data = subject.data_flow_sinks

            first_entry = sink_data.first
            sink_data.should == [first_entry]

            first_entry.function.name.should == 'blah'
            first_entry.trace.size.should == 2

            first_entry.trace[0].function.name.should  == 'onClick'
            first_entry.trace[0].function.source.should start_with 'function onClick'
            @browser.source.split("\n")[first_entry.trace[0].line].should include 'log_data_flow_sink'
            first_entry.trace[0].function.arguments.should == %w(some-arg arguments-arg here-arg)

            first_entry.trace[1].function.name.should == 'onsubmit'
            first_entry.trace[1].function.source.should start_with 'function onsubmit'
            @browser.source.split("\n")[first_entry.trace[1].line].should include 'onsubmit'
            first_entry.trace[1].function.arguments.size.should == 1

            event = first_entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            event['target'].should == form
            event['srcElement'].should == form
            event['type'].should == 'submit'
        end
    end

    describe '#debugging_data' do
        it 'returns debugging information' do
            load "debug?input=#{subject.stub.function(:debug, 1)}"
            @browser.watir.form.submit
            subject.debugging_data.should be_any
        end

        context 'by default' do
            it 'returns []' do
                subject.debugging_data.should == []
            end
        end
    end

    describe '#debug' do
        context 'when debugging is enabled' do
            it 'logs debugging data' do
                load "debug?input=#{subject.stub.function(:debug, 1)}"

                subject.enable_debugging = true

                @browser.watir.form.submit
                debugging_data = subject.debugging_data

                first_entry = debugging_data.first
                debugging_data.should == [first_entry]

                first_entry.data.should == [1]
                first_entry.trace.size.should == 2

                first_entry.trace[0].function.name.should == 'onClick'
                first_entry.trace[0].function.source.should start_with 'function onClick'
                @browser.source.split("\n")[first_entry.trace[0].line].should include 'debug(1)'
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
        end

        context 'when debugging is disabled' do
            it 'does not log anything' do
                load "debug?input=#{subject.stub.function(:debug, 1)}"

                subject.enable_debugging = false

                @browser.watir.form.submit
                subject.debugging_data.should be_empty
            end
        end
    end

end
