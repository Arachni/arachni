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
    let(:taint) { @browser.generate_token }

    after( :each ) do
        @browser.shutdown
    end

    it 'is aliased to _token_taint_tracer' do
        load "debug?input=_#{@javascript.token}_taint_tracer.log_execution_flow_sink()"
        @browser.watir.form.submit
        expect(subject.execution_flow_sinks).to be_any
    end

    it 'is aliased to _tokentainttracer' do
        load "debug?input=_#{@javascript.token}tainttracer.log_execution_flow_sink()"
        @browser.watir.form.submit
        expect(subject.execution_flow_sinks).to be_any
    end

    describe '#initialized' do
        it 'returns true' do
            expect(subject.initialized).to be_truthy
        end
    end

    describe '#class' do
        it "returns #{described_class}" do
            expect(subject.class).to eq(described_class)
        end
    end

    describe '#taints=' do
        it 'sets the taints to be traced' do
            subject.taints = [taint]
            expect(subject.taints).to eq([taint])
        end

        context 'when multiple taints are set' do
            it 'logs them in groups' do
                taint1 = 'taint1'
                taint2 = 'taint2'

                @javascript.custom_code = @taint_tracer.stub.function(
                    :taints=,
                    {
                        taint1 => {
                            trace: true
                        },
                        taint2 => {
                            trace: true
                        }
                    }
                )

                load "/data_trace/multiple-taints?taint1=#{taint1}&taint2=#{taint2}"

                sink = subject.data_flow_sinks[taint1]

                entry = sink[0]
                expect(entry.object).to eq('Window')
                expect(entry.function.name).to eq('process')
                expect(entry.function.source).to start_with 'function process'
                expect(entry.function.arguments).to eq([
                    {
                        'my_data11' => 'blah11',
                        'input11'   => taint1
                    }
                ])
                expect(entry.tainted_value).to eq(taint1)
                expect(entry.taint).to eq(taint1)
                expect(@browser.source.split("\n")[entry.trace[0].line-1]).to include 'process('

                entry = sink[1]
                expect(entry.object).to eq('Window')
                expect(entry.function.name).to eq('process')
                expect(entry.function.source).to start_with 'function process'
                expect(entry.function.arguments).to eq([
                    {
                        'my_data12' => 'blah12',
                        'input12'   => taint1
                    }
                ])
                expect(entry.tainted_value).to eq(taint1)
                expect(entry.taint).to eq(taint1)
                expect(@browser.source.split("\n")[entry.trace[0].line-1]).to include 'process('

                sink = subject.data_flow_sinks[taint2]

                entry = sink[0]
                expect(entry.object).to eq('Window')
                expect(entry.function.name).to eq('process')
                expect(entry.function.source).to start_with 'function process'
                expect(entry.function.arguments).to eq([
                    {
                        'my_data21' => 'blah21',
                        'input21'   => taint2
                    }
                ])
                expect(entry.tainted_value).to eq(taint2)
                expect(entry.taint).to eq(taint2)
                expect(@browser.source.split("\n")[entry.trace[0].line - 1]).to include 'process('

                entry = sink[1]
                expect(entry.object).to eq('Window')
                expect(entry.function.name).to eq('process')
                expect(entry.function.source).to start_with 'function process'
                expect(entry.function.arguments).to eq([
                    {
                        'my_data22' => 'blah22',
                        'input22'   => taint2
                    }
                ])
                expect(entry.tainted_value).to eq(taint2)
                expect(entry.taint).to eq(taint2)
                expect(@browser.source.split("\n")[entry.trace[0].line - 1]).to include 'process('
            end
        end

        context 'when tainted data pass through' do
            before { @javascript.taint = taint }

            it 'traces the taint up to a depth of 5' do
                load_with_taint 'data_trace/taint_depth/4'
                expect(subject.data_flow_sinks).to be_any

                load_with_taint 'data_trace/taint_depth/5'
                expect(subject.data_flow_sinks).to be_empty
            end

            context 'user-defined global functions' do
                it 'logs it' do
                    load_with_taint 'data_trace/user-defined-global-functions'

                    sink = subject.data_flow_sinks[taint]

                    entry = sink[0]
                    expect(entry.object).to eq('Window')
                    expect(entry.function.name).to eq('process')
                    expect(entry.function.source).to start_with 'function process'
                    expect(entry.function.arguments).to eq([
                        {
                            'my_data' => 'blah',
                            'input'   => taint
                        }
                    ])
                    expect(entry.tainted_value).to eq(taint)
                    expect(entry.taint).to eq(taint)
                    expect(@browser.source.split("\n")[entry.trace[0].line-1]).to include 'process('
                end
            end

            context 'window' do
                %w(escape unescape encodeURIComponent decodeURIComponent encodeURI decodeURI).each do |function|
                    context ".#{function}" do
                        it 'logs it' do
                            load_with_taint "data_trace/window.#{function}"

                            sink = subject.data_flow_sinks[taint]

                            entry = sink[0]
                            expect(entry.object).to eq('Window')
                            expect(entry.function.name).to eq(function)
                            expect(entry.function.source).to start_with "function #{function}"
                            expect(entry.function.arguments).to eq([ taint ])
                            expect(entry.tainted_value).to eq(taint)
                            expect(entry.taint).to eq(taint)
                            expect(@browser.source.split("\n")[entry.trace[0].line - 1]).to include "#{function}("
                        end
                    end
                end
            end

            context 'XMLHttpRequest' do
                context '.open' do
                    it 'logs it' do
                        load_with_taint 'data_trace/XMLHttpRequest.open'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('XMLHttpRequestPrototype')
                        expect(entry.function.name).to eq('open')
                        expect(entry.function.arguments).to eq([
                            'GET', "/?taint=#{taint}", true
                        ])
                        expect(entry.tainted_value).to eq("/?taint=#{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'open('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.send' do
                    it 'logs it' do
                        load_with_taint 'data_trace/XMLHttpRequest.send'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('XMLHttpRequestPrototype')
                        expect(entry.function.name).to eq('send')
                        expect(entry.function.arguments).to eq([ "taint=#{taint}" ])
                        expect(entry.tainted_value).to eq("taint=#{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'send('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.setRequestHeader' do
                    it 'logs it' do
                        load_with_taint 'data_trace/XMLHttpRequest.setRequestHeader'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('XMLHttpRequestPrototype')
                        expect(entry.function.name).to eq('setRequestHeader')
                        expect(entry.function.arguments).to eq([ 'X-My-Header', "stuff-#{taint}" ])
                        expect(entry.tainted_value).to eq("stuff-#{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'setRequestHeader('
                        expect(trace.url).to eq(@browser.url)
                    end
                end
            end

            context 'AngularJS' do
                context '.element' do
                    it 'logs it' do
                        load_with_taint 'data_trace/AngularJS.element'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[1]
                        expect(entry.object).to eq('angular')
                        expect(entry.function.name).to eq('JQLite')
                        expect(entry.function.arguments).to eq(["<div>Stuff #{taint}</div>"])
                        expect(entry.tainted_value).to eq("<div>Stuff #{taint}</div>")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'angular.element('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '$http' do
                    context '.delete' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/$http.delete'

                            sink = subject.data_flow_sinks[taint]

                            entry = sink[1]
                            expect(entry.object).to eq('angular.$http')
                            expect(entry.function.name).to eq('delete')
                            expect(entry.function.arguments).to eq([ "/#{taint}" ])
                            expect(entry.tainted_value).to eq("/#{taint}")
                            expect(entry.taint).to eq(taint)
                            expect(entry.trace[0].url).to eq(@browser.url)

                            entry = sink[3]
                            expect(entry.object).to eq('XMLHttpRequestPrototype')
                            expect(entry.function.name).to eq('open')
                            expect(entry.function.arguments).to eq([
                                'DELETE', "/#{taint}", true
                            ])
                            expect(entry.tainted_value).to eq("/#{taint}")
                            expect(entry.taint).to eq(taint)
                            expect(entry.trace[0].url).to eq("#{@url}angular.js")
                        end
                    end

                    context '.head' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/$http.head'

                            sink = subject.data_flow_sinks[taint]

                            entry = sink[1]
                            expect(entry.object).to eq('angular.$http')
                            expect(entry.function.name).to eq('head')
                            expect(entry.function.arguments).to eq([ "/#{taint}" ])
                            expect(entry.tainted_value).to eq("/#{taint}")
                            expect(entry.taint).to eq(taint)
                            expect(entry.trace[0].url).to eq(@browser.url)

                            entry = sink[3]
                            expect(entry.object).to eq('XMLHttpRequestPrototype')
                            expect(entry.function.name).to eq('open')
                            expect(entry.function.arguments).to eq([
                                'HEAD', "/#{taint}", true
                            ])
                            expect(entry.tainted_value).to eq("/#{taint}")
                            expect(entry.taint).to eq(taint)
                            expect(entry.trace[0].url).to eq("#{@url}angular.js")
                        end
                    end

                    context '.jsonp' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/$http.jsonp'

                            sink = subject.data_flow_sinks[taint]

                            entry = sink[1]
                            expect(entry.object).to eq('angular.$http')
                            expect(entry.function.name).to eq('jsonp')
                            expect(entry.function.arguments).to eq([ "/jsonp-#{taint}" ])
                            expect(entry.tainted_value).to eq("/jsonp-#{taint}")
                            expect(entry.taint).to eq(taint)
                            expect(entry.trace[0].url).to eq(@browser.url)

                            entry = sink[2]
                            expect(entry.object).to eq('ElementPrototype')
                            expect(entry.function.name).to eq('setAttribute')
                            expect(entry.function.arguments).to eq([
                                'href', "/jsonp-#{taint}"
                            ])
                            expect(entry.tainted_value).to eq("/jsonp-#{taint}")
                            expect(entry.taint).to eq(taint)
                            expect(entry.trace[0].url).to eq("#{@url}angular.js")
                        end
                    end

                    context '.put' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/$http.put'

                            sink = subject.data_flow_sinks[taint]

                            entry = sink[1]
                            expect(entry.object).to eq('angular.$http')
                            expect(entry.function.name).to eq('put')
                            expect(entry.function.arguments).to eq([
                                '/', "Stuff #{taint}"
                            ])
                            expect(entry.tainted_value).to eq("Stuff #{taint}")
                            expect(entry.taint).to eq(taint)
                            expect(entry.trace[0].url).to eq(@browser.url)

                            entry = sink[2]
                            expect(entry.object).to eq('XMLHttpRequestPrototype')
                            expect(entry.function.name).to eq('send')
                            expect(entry.function.arguments).to eq([ "Stuff #{taint}" ])
                            expect(entry.tainted_value).to eq("Stuff #{taint}")
                            expect(entry.taint).to eq(taint)
                            expect(entry.trace[0].url).to eq("#{@url}angular.js")
                        end
                    end

                    context '.get' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/$http.get'

                            sink = subject.data_flow_sinks[taint]

                            entry = sink[1]
                            expect(entry.object).to eq('angular.$http')
                            expect(entry.function.name).to eq('get')
                            expect(entry.function.arguments).to eq([ "/#{taint}" ])
                            expect(entry.tainted_value).to eq("/#{taint}")
                            expect(entry.taint).to eq(taint)
                            expect(entry.trace[0].url).to eq(@browser.url)

                            entry = sink[3]
                            expect(entry.object).to eq('XMLHttpRequestPrototype')
                            expect(entry.function.name).to eq('open')
                            expect(entry.function.arguments).to eq([
                                'GET', "/#{taint}", true
                            ])
                            expect(entry.tainted_value).to eq("/#{taint}")
                            expect(entry.taint).to eq(taint)
                            expect(entry.trace[0].url).to eq("#{@url}angular.js")
                        end
                    end

                    context '.post' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/$http.post'

                            sink = subject.data_flow_sinks[taint]

                            entry = sink[1]
                            expect(entry.object).to eq('angular.$http')
                            expect(entry.function.name).to eq('post')
                            expect(entry.function.arguments).to eq([
                                '/', '',
                                {
                                    'params' => {
                                        'stuff' => "Stuff #{taint}"
                                    },
                                    'method' => 'post',
                                    'url'    => '/',
                                    'data'   => ''
                                }
                            ])
                            expect(entry.tainted_value).to eq("Stuff #{taint}")
                            expect(entry.taint).to eq(taint)
                            expect(entry.trace[0].url).to eq(@browser.url)

                            entry = sink[3]
                            expect(entry.object).to eq('XMLHttpRequestPrototype')
                            expect(entry.function.name).to eq('open')
                            expect(entry.function.arguments).to eq([
                                'POST', "/?stuff=Stuff+#{taint}", true
                            ])
                            expect(entry.tainted_value).to eq("/?stuff=Stuff+#{taint}")
                            expect(entry.taint).to eq(taint)
                            expect(entry.trace[0].url).to eq("#{@url}angular.js")
                        end
                    end
                end

                context 'ngRoute' do
                    context 'template' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/ngRoute/'

                            sink = subject.data_flow_sinks[taint]

                            # ngRoute module first schedules an HTTP request to grab
                            # the template from the given 'templateUrl'...
                            entry = sink[6]
                            expect(entry.object).to eq('XMLHttpRequestPrototype')
                            expect(entry.function.name).to eq('open')
                            expect(entry.function.arguments).to eq([
                                'GET', "template.html?taint=#{taint}", true
                            ])
                            expect(entry.tainted_value).to eq("template.html?taint=#{taint}")
                            expect(entry.taint).to eq(taint)
                            expect(entry.trace[0].url).to eq("#{@url}angular.js")

                            #... and then updates the app with the (tainted) template content.
                            entry = sink[7]
                            expect(entry.object).to eq('angular.element')
                            expect(entry.function.name).to eq('html')
                            expect(entry.function.arguments).to eq(["Blah blah blah #{taint}\n"])
                            expect(entry.tainted_value).to eq("Blah blah blah #{taint}\n")
                            expect(entry.taint).to eq(taint)
                            expect(entry.trace[0].url).to eq("#{@url}angular-route.js")
                        end
                    end
                end

                context 'jqLite' do
                    context '.html' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/jqLite.html'

                            sink = subject.data_flow_sinks[taint]

                            entry = sink[1]
                            expect(entry.object).to eq('angular.element')
                            expect(entry.function.name).to eq('html')
                            expect(entry.function.arguments).to eq(["Stuff #{taint}"])
                            expect(entry.tainted_value).to eq("Stuff #{taint}")
                            expect(entry.taint).to eq(taint)

                            trace = entry.trace[0]
                            expect(@browser.source.split("\n")[trace.line - 2]).to include 'html('
                            expect(trace.url).to eq(@browser.url)
                        end
                    end

                    context '.text' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/jqLite.text'

                            sink = subject.data_flow_sinks[taint]

                            entry = sink[1]
                            expect(entry.object).to eq('angular.element')
                            expect(entry.function.name).to eq('text')
                            expect(entry.function.arguments).to eq(["Stuff #{taint}"])
                            expect(entry.tainted_value).to eq("Stuff #{taint}")
                            expect(entry.taint).to eq(taint)

                            trace = entry.trace[0]
                            expect(@browser.source.split("\n")[trace.line - 2]).to include 'text('
                            expect(trace.url).to eq(@browser.url)
                        end
                    end

                    context '.append' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/jqLite.append'

                            sink = subject.data_flow_sinks[taint]

                            entry = sink[1]
                            expect(entry.object).to eq('angular.element')
                            expect(entry.function.name).to eq('append')
                            expect(entry.function.arguments).to eq(["Stuff #{taint}"])
                            expect(entry.tainted_value).to eq("Stuff #{taint}")
                            expect(entry.taint).to eq(taint)

                            trace = entry.trace[0]
                            expect(@browser.source.split("\n")[trace.line - 1]).to include 'append('
                            expect(trace.url).to eq(@browser.url)
                        end
                    end

                    context '.prepend' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/jqLite.prepend'

                            sink = subject.data_flow_sinks[taint]

                            entry = sink[1]
                            expect(entry.object).to eq('angular.element')
                            expect(entry.function.name).to eq('prepend')
                            expect(entry.function.arguments).to eq(["Stuff #{taint}"])
                            expect(entry.tainted_value).to eq("Stuff #{taint}")
                            expect(entry.taint).to eq(taint)

                            trace = entry.trace[0]
                            expect(@browser.source.split("\n")[trace.line - 1]).to include 'prepend('
                            expect(trace.url).to eq(@browser.url)
                        end
                    end

                    context '.prop' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/jqLite.prop'

                            sink = subject.data_flow_sinks[taint]

                            entry = sink[1]
                            expect(entry.object).to eq('angular.element')
                            expect(entry.function.name).to eq('prop')
                            expect(entry.function.arguments).to eq([ 'stuff', "Stuff #{taint}"])
                            expect(entry.tainted_value).to eq("Stuff #{taint}")
                            expect(entry.taint).to eq(taint)

                            trace = entry.trace[0]
                            expect(@browser.source.split("\n")[trace.line - 1]).to include 'prop('
                            expect(trace.url).to eq(@browser.url)
                        end
                    end

                    context '.replaceWith' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/jqLite.replaceWith'

                            sink = subject.data_flow_sinks[taint]

                            entry = sink[1]
                            expect(entry.object).to eq('angular.element')
                            expect(entry.function.name).to eq('replaceWith')
                            expect(entry.function.arguments).to eq([ "Stuff #{taint}"])
                            expect(entry.tainted_value).to eq("Stuff #{taint}")
                            expect(entry.taint).to eq(taint)

                            trace = entry.trace[0]
                            expect(@browser.source.split("\n")[trace.line - 2]).to include 'replaceWith('
                            expect(trace.url).to eq(@browser.url)
                        end
                    end

                    context '.val' do
                        it 'logs it' do
                            load_with_taint 'data_trace/AngularJS/jqLite.val'

                            sink = subject.data_flow_sinks[taint]

                            entry = sink[1]
                            expect(entry.object).to eq('angular.element')
                            expect(entry.function.name).to eq('val')
                            expect(entry.function.arguments).to eq([ "Stuff #{taint}"])
                            expect(entry.tainted_value).to eq("Stuff #{taint}")
                            expect(entry.taint).to eq(taint)

                            trace = entry.trace[0]
                            expect(@browser.source.split("\n")[trace.line - 1]).to include 'val('
                            expect(trace.url).to eq(@browser.url)
                        end
                    end
                end
            end

            context 'jQuery' do
                context '.cookie' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.cookie'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('jQuery')
                        expect(entry.function.name).to eq('cookie')
                        expect(entry.function.arguments).to eq(['cname', "mystuff #{taint}"])
                        expect(entry.tainted_value).to eq("mystuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'cookie('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.ajax' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.ajax'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('jQuery')
                        expect(entry.function.name).to eq('ajax')
                        expect(entry.function.arguments).to eq([
                            {
                                'url'  => '/',
                                'data' => {
                                    'stuff' => "mystuff #{taint}"
                                }
                            }
                        ])
                        expect(entry.tainted_value).to eq("mystuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'ajax('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.get' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.get'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('jQuery')
                        expect(entry.function.name).to eq('get')
                        expect(entry.function.arguments).to eq([
                            '/',
                            { 'stuff' => "mystuff #{taint}" }
                        ])
                        expect(entry.tainted_value).to eq("mystuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'get('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.post' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.post'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('jQuery')
                        expect(entry.function.name).to eq('post')
                        expect(entry.function.arguments).to eq([ "/#{taint}" ])
                        expect(entry.tainted_value).to eq("/#{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'post('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.load' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.load'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('jQuery')
                        expect(entry.function.name).to eq('load')
                        expect(entry.function.arguments).to eq([ "/#{taint}" ])
                        expect(entry.tainted_value).to eq("/#{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'load('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.html' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.html'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('jQuery')
                        expect(entry.function.name).to eq('html')
                        expect(entry.function.arguments).to eq(["Stuff #{taint}"])
                        expect(entry.tainted_value).to eq("Stuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 2]).to include 'html('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.text' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.text'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('jQuery')
                        expect(entry.function.name).to eq('text')
                        expect(entry.function.arguments).to eq(["Stuff #{taint}"])
                        expect(entry.tainted_value).to eq("Stuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 2]).to include 'text('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.append' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.append'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('jQuery')
                        expect(entry.function.name).to eq('append')
                        expect(entry.function.arguments).to eq(["Stuff #{taint}"])
                        expect(entry.tainted_value).to eq("Stuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'append('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.prepend' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.prepend'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('jQuery')
                        expect(entry.function.name).to eq('prepend')
                        expect(entry.function.arguments).to eq(["Stuff #{taint}"])
                        expect(entry.tainted_value).to eq("Stuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'prepend('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.before' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.before'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('jQuery')
                        expect(entry.function.name).to eq('before')
                        expect(entry.function.arguments).to eq(["Stuff #{taint}"])
                        expect(entry.tainted_value).to eq("Stuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'before('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.prop' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.prop'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('jQuery')
                        expect(entry.function.name).to eq('prop')
                        expect(entry.function.arguments).to eq([ 'stuff', "Stuff #{taint}"])
                        expect(entry.tainted_value).to eq("Stuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'prop('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.replaceWith' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.replaceWith'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('jQuery')
                        expect(entry.function.name).to eq('replaceWith')
                        expect(entry.function.arguments).to eq([ "Stuff #{taint}"])
                        expect(entry.tainted_value).to eq("Stuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 2]).to include 'replaceWith('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.val' do
                    it 'logs it' do
                        load_with_taint 'data_trace/jQuery.val'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('jQuery')
                        expect(entry.function.name).to eq('val')
                        expect(entry.function.arguments).to eq([ "Stuff #{taint}"])
                        expect(entry.tainted_value).to eq("Stuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'val('
                        expect(trace.url).to eq(@browser.url)
                    end
                end
            end

            context 'String' do
                context '.replace' do
                    it 'logs it' do
                        load_with_taint 'data_trace/String.replace'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('String')
                        expect(entry.function.name).to eq('replace')
                        expect(entry.function.source).to start_with 'function replace'
                        expect(entry.function.arguments).to eq([
                            'my', taint
                        ])
                        expect(entry.tainted_value).to eq(taint)
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'replace('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.concat' do
                    it 'logs it' do
                        load_with_taint 'data_trace/String.concat'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('String')
                        expect(entry.function.name).to eq('concat')
                        expect(entry.function.source).to start_with 'function concat'
                        expect(entry.function.arguments).to eq([ "stuff #{taint}" ])
                        expect(entry.tainted_value).to eq("stuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'concat('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.indexOf' do
                    it 'logs it' do
                        load_with_taint 'data_trace/String.indexOf'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('String')
                        expect(entry.function.name).to eq('indexOf')
                        expect(entry.function.source).to start_with 'function indexOf'
                        expect(entry.function.arguments).to eq([ "stuff #{taint}" ])
                        expect(entry.tainted_value).to eq("stuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'indexOf('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.lastIndexOf' do
                    it 'logs it' do
                        load_with_taint 'data_trace/String.lastIndexOf'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('String')
                        expect(entry.function.name).to eq('lastIndexOf')
                        expect(entry.function.source).to start_with 'function lastIndexOf'
                        expect(entry.function.arguments).to eq([ "stuff #{taint}" ])
                        expect(entry.tainted_value).to eq("stuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'lastIndexOf('
                        expect(trace.url).to eq(@browser.url)
                    end
                end
            end

            context 'HTMLElement' do
                context '.insertAdjacentHTML' do
                    it 'logs it' do
                        load_with_taint 'data_trace/HTMLElement.insertAdjacentHTML'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('HTMLElementPrototype')
                        expect(entry.function.name).to eq('insertAdjacentHTML')
                        expect(entry.function.source).to start_with 'function insertAdjacentHTML'
                        expect(entry.function.arguments).to eq([
                            'AfterBegin', "stuff #{taint} more stuff"
                        ])
                        expect(entry.tainted_value).to eq("stuff #{taint} more stuff")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'insertAdjacentHTML('
                        expect(trace.url).to eq(@browser.url)
                    end
                end
            end

            context 'Element' do
                context '.setAttribute' do
                    it 'logs it' do
                        load_with_taint 'data_trace/Element.setAttribute'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('ElementPrototype')
                        expect(entry.function.name).to eq('setAttribute')
                        expect(entry.function.source).to start_with 'function setAttribute'
                        expect(entry.function.arguments).to eq([
                            'my-attribute', "stuff #{taint} more stuff"
                        ])
                        expect(entry.tainted_value).to eq("stuff #{taint} more stuff")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'setAttribute('
                        expect(trace.url).to eq(@browser.url)
                    end
                end
            end

            context 'Document' do
                context '.createTextNode' do
                    it 'logs it' do
                        load_with_taint 'data_trace/Document.createTextNode'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('DocumentPrototype')
                        expect(entry.function.name).to eq('createTextNode')
                        expect(entry.function.source).to start_with 'function createTextNode'
                        expect(entry.function.arguments).to eq([ "node #{taint}" ])
                        expect(entry.tainted_value).to eq("node #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'document.createTextNode('
                        expect(trace.url).to eq(@browser.url)
                    end
                end
            end

            context 'CharacterData' do
                context '.insertData' do
                    it 'logs it' do
                        load_with_taint 'data_trace/CharacterData.insertData'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('CharacterDataPrototype')
                        expect(entry.function.name).to eq('insertData')
                        expect(entry.function.source).to start_with 'function insertData'
                        expect(entry.function.arguments).to eq([ "Stuff #{taint}" ])
                        expect(entry.tainted_value).to eq("Stuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'insertData('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.appendData' do
                    it 'logs it' do
                        load_with_taint 'data_trace/CharacterData.appendData'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('CharacterDataPrototype')
                        expect(entry.function.name).to eq('appendData')
                        expect(entry.function.source).to start_with 'function appendData'
                        expect(entry.function.arguments).to eq([ "Stuff #{taint}" ])
                        expect(entry.tainted_value).to eq("Stuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'appendData('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.replaceData' do
                    it 'logs it' do
                        load_with_taint 'data_trace/CharacterData.replaceData'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('CharacterDataPrototype')
                        expect(entry.function.name).to eq('replaceData')
                        expect(entry.function.source).to start_with 'function replaceData'
                        expect(entry.function.arguments).to eq([ 0, 0, "Stuff #{taint}" ])
                        expect(entry.tainted_value).to eq("Stuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'replaceData('
                        expect(trace.url).to eq(@browser.url)
                    end
                end
            end

            context 'Text' do
                context '.replaceWholeText' do
                    it 'logs it' do
                        load_with_taint 'data_trace/Text.replaceWholeText'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('TextPrototype')
                        expect(entry.function.name).to eq('replaceWholeText')
                        expect(entry.function.source).to start_with 'function replaceWholeText'
                        expect(entry.function.arguments).to eq([ "Stuff #{taint}" ])
                        expect(entry.tainted_value).to eq("Stuff #{taint}")
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'replaceWholeText('
                        expect(trace.url).to eq(@browser.url)
                    end
                end
            end

            context 'HTMLDocument' do
                context '.write' do
                    it 'logs it' do
                        load_with_taint 'data_trace/HTMLDocument.write'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('HTMLDocumentPrototype')
                        expect(entry.function.name).to eq('write')
                        expect(entry.function.source).to start_with 'function write'
                        expect(entry.function.arguments).to eq([
                            "Stuff here blah #{taint} more stuff nlahblah..."
                        ])
                        expect(entry.tainted_value).to eq(
                            "Stuff here blah #{taint} more stuff nlahblah..."
                        )
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'document.write('
                        expect(trace.url).to eq(@browser.url)
                    end
                end

                context '.writeln' do
                    it 'logs it' do
                        load_with_taint 'data_trace/HTMLDocument.writeln'

                        sink = subject.data_flow_sinks[taint]

                        entry = sink[0]
                        expect(entry.object).to eq('HTMLDocumentPrototype')
                        expect(entry.function.name).to eq('writeln')
                        expect(entry.function.source).to start_with 'function writeln'
                        expect(entry.function.arguments).to eq([
                            "Stuff here blah #{taint} more stuff nlahblah..."
                        ])
                        expect(entry.tainted_value).to eq(
                            "Stuff here blah #{taint} more stuff nlahblah..."
                        )
                        expect(entry.taint).to eq(taint)

                        trace = entry.trace[0]
                        expect(@browser.source.split("\n")[trace.line - 1]).to include 'document.writeln('
                        expect(trace.url).to eq(@browser.url)
                    end
                end
            end
        end
    end

    describe '#taints' do
        context 'by default' do
            it 'returns {' do
                expect(subject.taints).to eq({})
            end
        end
    end

    describe '#enable_debugging=' do
        it 'sets the debugging flag' do
            subject.enable_debugging = false
            expect(subject.enable_debugging).to eq(false)
        end
    end

    describe '#enable_debugging' do
        context 'by default' do
            it 'returns true' do
                expect(subject.enable_debugging).to eq(true)
            end
        end
    end

    describe '#execution_flow_sinks' do
        it 'returns sink data' do
            load "debug?input=#{subject.stub.function(:log_execution_flow_sink)}"
            @browser.watir.form.submit
            expect(subject.execution_flow_sinks).to be_any
        end

        context 'by default' do
            it 'returns []' do
                expect(subject.execution_flow_sinks).to eq([])
            end
        end
    end

    describe '#data_flow_sinks' do
        it 'returns sink data' do
            @javascript.taint = 'taint'

            load "debug?input=#{subject.stub.function(:log_data_flow_sink, 'taint', { function: 'blah' })}"
            @browser.watir.form.submit
            expect(subject.data_flow_sinks['taint']).to be_any
        end

        context 'by default' do
            it 'returns {}' do
                expect(subject.data_flow_sinks).to eq({})
            end
        end
    end

    describe '#flush_data_flow_sinks' do
        before do
            @javascript.taint = 'taint'
        end

        it 'returns sink data' do
            load "debug?input=#{subject.stub.function(:log_data_flow_sink, 'taint', { function: { name: 'blah' } })}"
            @browser.watir.form.submit
            sink_data = subject.flush_data_flow_sinks['taint']

            first_entry = sink_data.first
            expect(sink_data).to eq([first_entry])

            expect(first_entry.function.name).to eq('blah')

            expect(first_entry.trace[0].function.name).to eq('onClick')
            expect(first_entry.trace[0].function.source).to start_with 'function onClick'
            expect(@browser.source.split("\n")[first_entry.trace[0].line - 1]).to include 'log_data_flow_sink'
            expect(first_entry.trace[0].function.arguments).to eq(%w(some-arg arguments-arg here-arg))

            expect(first_entry.trace[1].function.name).to eq('onsubmit')
            expect(first_entry.trace[1].function.source).to start_with 'function onsubmit'
            expect(@browser.source.split("\n")[first_entry.trace[1].line - 1]).to include 'onsubmit'
            expect(first_entry.trace[1].function.arguments.size).to eq(1)

            event = first_entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            expect(event['target']).to eq(form)
            expect(event['srcElement']).to eq(form)
            expect(event['type']).to eq('submit')
        end

        it 'empties the sink' do
            load "debug?input=#{subject.stub.function(:log_data_flow_sink, 'taint', { function: { name: 'blah' } })}"
            @browser.watir.form.submit
            subject.flush_data_flow_sinks
            expect(subject.data_flow_sinks).to be_empty
        end
    end

    describe '#flush_execution_flow_sinks' do
        it 'returns sink data' do
            load "debug?input=#{subject.stub.function(:log_execution_flow_sink, 1)}"
            @browser.watir.form.submit
            sink_data = subject.flush_execution_flow_sinks

            first_entry = sink_data.first
            expect(sink_data).to eq([first_entry])

            expect(first_entry.data).to eq([1])

            expect(first_entry.trace[0].function.name).to eq('onClick')
            expect(first_entry.trace[0].function.source).to start_with 'function onClick'
            expect(@browser.source.split("\n")[first_entry.trace[0].line - 1]).to include 'log_execution_flow_sink(1)'
            expect(first_entry.trace[0].function.arguments).to eq(%w(some-arg arguments-arg here-arg))

            expect(first_entry.trace[1].function.name).to eq('onsubmit')
            expect(first_entry.trace[1].function.source).to start_with 'function onsubmit'
            expect(@browser.source.split("\n")[first_entry.trace[1].line - 1]).to include 'onsubmit'
            expect(first_entry.trace[1].function.arguments.size).to eq(1)

            event = first_entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            expect(event['target']).to eq(form)
            expect(event['srcElement']).to eq(form)
            expect(event['type']).to eq('submit')
        end

        it 'empties the sink' do
            load "debug?input=#{subject.stub.function(:log_data_flow_sink)}"
            @browser.watir.form.submit
            subject.flush_execution_flow_sinks
            expect(subject.execution_flow_sinks).to be_empty
        end
    end

    describe '#log_execution_flow_sink' do
        it 'logs a sink' do
            load "debug?input=#{subject.stub.function(:log_execution_flow_sink, 1)}"
            @browser.watir.form.submit
            sink_data = subject.execution_flow_sinks

            first_entry = sink_data.first
            expect(sink_data).to eq([first_entry])

            expect(first_entry.data).to eq([1])

            expect(first_entry.trace[0].function.name).to  eq('onClick')
            expect(first_entry.trace[0].function.source).to start_with 'function onClick'
            expect(@browser.source.split("\n")[first_entry.trace[0].line - 1]).to include 'log_execution_flow_sink(1)'
            expect(first_entry.trace[0].function.arguments).to eq(%w(some-arg arguments-arg here-arg))

            expect(first_entry.trace[1].function.name).to eq('onsubmit')
            expect(first_entry.trace[1].function.source).to start_with 'function onsubmit'
            expect(@browser.source.split("\n")[first_entry.trace[1].line - 1]).to include 'onsubmit'
            expect(first_entry.trace[1].function.arguments.size).to eq(1)

            event = first_entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            expect(event['target']).to eq(form)
            expect(event['srcElement']).to eq(form)
            expect(event['type']).to eq('submit')
        end

        it 'is limited to 50' do
            load 'debug'

            100.times do |i|
                @browser.javascript.run( subject.stub.function( :log_execution_flow_sink, i ) )
            end

            sinks = subject.execution_flow_sinks
            expect(sinks.size).to eq(50)

            50.times do |i|
                expect(sinks[i].data).to eq([50 + i])
            end
        end
    end

    describe '#log_data_flow_sink' do
        before do
            @javascript.taint = 'taint'
        end

        it 'logs a sink' do
            load "debug?input=#{subject.stub.function(:log_data_flow_sink, 'taint', { function: { name: 'blah' } })}"
            @browser.watir.form.submit
            sink_data = subject.data_flow_sinks['taint']

            first_entry = sink_data.first
            expect(sink_data).to eq([first_entry])

            expect(first_entry.function.name).to eq('blah')

            expect(first_entry.trace[0].function.name).to  eq('onClick')
            expect(first_entry.trace[0].function.source).to start_with 'function onClick'
            expect(@browser.source.split("\n")[first_entry.trace[0].line - 1]).to include 'log_data_flow_sink'
            expect(first_entry.trace[0].function.arguments).to eq(%w(some-arg arguments-arg here-arg))

            expect(first_entry.trace[1].function.name).to eq('onsubmit')
            expect(first_entry.trace[1].function.source).to start_with 'function onsubmit'
            expect(@browser.source.split("\n")[first_entry.trace[1].line - 1]).to include 'onsubmit'
            expect(first_entry.trace[1].function.arguments.size).to eq(1)

            event = first_entry.trace[1].function.arguments.first

            form = "<form id=\"my_form\" onsubmit=\"onClick('some-arg', 'arguments-arg', 'here-arg'); return false;\">\n        </form>"
            expect(event['target']).to eq(form)
            expect(event['srcElement']).to eq(form)
            expect(event['type']).to eq('submit')
        end

        it 'is limited to 50 per taint' do
            load 'debug'

            100.times do |i|
                @browser.javascript.run(
                    subject.stub.function(
                        :log_data_flow_sink,
                        'taint',
                        {
                            function: {
                                name: "f_#{i}"
                            }
                        }
                    )
                )
            end

            sinks = subject.data_flow_sinks['taint']
            expect(sinks.size).to eq(50)

            50.times do |i|
                expect(sinks[i].function.name).to eq("f_#{i+50}")
            end
        end

    end

    describe '#debugging_data' do
        it 'returns debugging information' do
            load "debug?input=#{subject.stub.function(:debug, 1)}"
            @browser.watir.form.submit
            expect(subject.debugging_data).to be_any
        end

        context 'by default' do
            it 'returns []' do
                expect(subject.debugging_data).to eq([])
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
                expect(debugging_data).to eq([first_entry])

                expect(first_entry.data).to eq([1])

                expect(first_entry.trace[0].function.name).to eq('onClick')
                expect(first_entry.trace[0].function.source).to start_with 'function onClick'
                expect(@browser.source.split("\n")[first_entry.trace[0].line - 1]).to include 'debug(1)'
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
        end

        context 'when debugging is disabled' do
            it 'does not log anything' do
                load "debug?input=#{subject.stub.function(:debug, 1)}"

                subject.enable_debugging = false

                @browser.watir.form.submit
                expect(subject.debugging_data).to be_empty
            end
        end
    end

end
