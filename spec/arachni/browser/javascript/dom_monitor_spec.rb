require 'spec_helper'

describe Arachni::Browser::Javascript::DOMMonitor do

    before( :all ) do
        @url = Arachni::Utilities.normalize_url( web_server_url_for( :dom_monitor ) )
    end

    before( :each ) do
        @browser      = Arachni::Browser.new
        @javascript   = @browser.javascript
        @browser.load @url
        @dom_monitor = described_class.new( @javascript )
    end

    def load( path )
        @browser.load "#{@url}/#{path}"
    end

    let(:javascript) { @javascript }
    subject { @dom_monitor }

    after( :each ) do
        Arachni::HTTP::Client.reset
        @browser.shutdown
    end

    describe '#class' do
        it "returns #{described_class}" do
            expect(subject.class).to eq(described_class)
        end
    end

    describe '#initialized' do
        it 'returns true' do
            expect(subject.initialized).to be_truthy
        end
    end

    it 'adds _arachni_events property to elements holding the tracked events' do
        load '/elements_with_events/listeners'

        expect(javascript.run( "return document.getElementById('my-button')._arachni_events")).to eq([
            [
                'click',
                'function (my_button_click) {}'
            ],
            [
                'click',
                'function (my_button_click2) {}'
            ],
            [
                'onmouseover',
                'function (my_button_onmouseover) {}'
            ]
        ])

        expect(javascript.run( "return document.getElementById('my-button2')._arachni_events")).to eq([
            [
                'click',
                'function (my_button2_click) {}'
            ]
        ])

        expect(javascript.run( "return document.getElementById('my-button3')._arachni_events")).to be_nil
    end

    describe '#digest' do
        it 'returns a string digest of the current DOM tree' do
            load '/digest'
            expect(subject.digest).to eq('<HTML><HEAD><SCRIPT src=http://' <<
                'javascript.browser.arachni/polyfills.js><SCRIPT src=http://javascri' <<
                'pt.browser.arachni/' <<'taint_tracer.js><SCRIPT src' <<
                '=http://javascript.browser.arachni/dom_monitor.js><SCRIPT>' <<
                '<BODY onload=void();><DIV id=my-id-div><DIV class=my-class' <<
                '-div><STRONG><EM><I><B><STRONG><SCRIPT><SCRIPT type=text/' <<
                'javascript><A href=#stuff>')
        end

        it 'does not include <p> elements' do
            load '/digest/p'
            expect(subject.digest).to eq('<HTML><HEAD><SCRIPT src=http://' <<
                'javascript.browser.arachni/polyfills.js><SCRIPT src=http://javascript' <<
                '.browser.arachni/taint_tracer.js><SCRIPT src=http://' <<
                'javascript.browser.arachni/dom_monitor.js><SCRIPT><BODY><STRONG>')
        end

        it "does not include 'data-arachni-id' attributes" do
            load '/digest/data-arachni-id'
            expect(subject.digest).to eq('<HTML><HEAD><SCRIPT src=http://' <<
                'javascript.browser.arachni/polyfills.js><SCRIPT src=http://javascript' <<
                '.browser.arachni/taint_tracer.js><SCRIPT src=http://' <<
                'javascript.browser.arachni/dom_monitor.js><SCRIPT><BODY><DIV ' <<
                'id=my-id-div><DIV class=my-class-div>')
        end
    end

    describe '#timeouts' do
        it 'keeps track of setTimeout() timers' do
            load '/timeouts'

            expect(subject.timeouts).to eq([
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
            ])

            expect(@browser.load_delay).to eq(2000)
            expect(@browser.cookies.size).to eq(4)
            expect(@browser.cookies.map { |c| c.to_s }.sort).to eq([
                'timeout3=post-2000',
                'timeout2=post-1500',
                'timeout1=post-1000',
                'timeout=pre'
            ].sort)
        end
    end

    describe '#intervals' do
        it 'keeps track of setInterval() timers' do
            load '/intervals'

            expect(subject.intervals).to eq([
                [
                    "function (name, value) {\n            document.cookie = name + \"=post-\" + value;\n        }",
                    2000, 'timeout1', 2000
                ]
            ])

            sleep 2
            expect(@browser.cookies.size).to eq(2)
            expect(@browser.cookies.map { |c| c.to_s }.sort).to eq([
                'timeout1=post-2000',
                'timeout=pre'
            ].sort)
        end
    end

    describe '#elements_with_events' do
        it 'skips non visible elements' do
            load '/elements_with_events/with-hidden'

            expect(subject.elements_with_events).to eq([
                {
                    'tag_name' => 'button',
                    'events' => [
                        [
                            'click',
                            'function (my_button_click) {}'
                        ]
                    ],
                    'attributes' => {
                        'onclick' => 'handler_1()',
                        'id' => 'my-button'
                    }
                }
            ])
        end

        context 'when it has a dot delimited custom event' do
            it 'retains the first part' do
                load '/elements_with_events/custom-dot-delimited'

                expect(subject.elements_with_events).to eq([
                    {
                        "tag_name"   => "button",
                        "events"     =>
                            [
                                [
                                    "click",
                                    "function (e) {\n\t\t\t\t// Discard the second event of a jQuery.event.trigger() and\n\t\t\t\t// when an event is called after a page has unloaded\n\t\t\t\treturn typeof jQuery !== core_strundefined && (!e || jQuery.event.triggered !== e.type) ?\n\t\t\t\t\tjQuery.event.dispatch.apply( eventHandle.elem, arguments ) :\n\t\t\t\t\tundefined;\n\t\t\t}"
                                ],
                                [
                                    "load",
                                    "function () {\n\t\tdocument.removeEventListener( \"DOMContentLoaded\", completed, false );\n\t\twindow.removeEventListener( \"load\", completed, false );\n\t\tjQuery.ready();\n\t}"
                                ]
                            ],
                        "attributes" => {
                            "id" => "my-button"
                        }
                    }
                ])
            end
        end

        context 'when using' do
            context 'event attributes' do
                it 'returns information about all DOM elements along with their events' do
                    load '/elements_with_events/attributes'

                    expect(subject.elements_with_events).to eq([
                        {
                            'tag_name'   => 'button',
                            'events'     => [],
                            'attributes' => { 'onclick' => 'handler_1()', 'id' => 'my-button' }
                        },
                        {
                            'tag_name'   => 'button',
                            'events'     => [],
                            'attributes' => { 'onclick' => 'handler_2()', 'id' => 'my-button2' }
                         },
                         {
                             'tag_name' => 'button',
                             'events' => [],
                             'attributes' => { 'onclick' => 'handler_3()', 'id' => 'my-button3' }
                         }
                    ])
                end
            end

            context 'event listeners' do
                it 'returns information about all DOM elements along with their events' do
                    load '/elements_with_events/listeners'

                    expect(subject.elements_with_events).to eq([
                        {
                            'tag_name'   => 'button',
                            'events'     => [
                                ['click', 'function (my_button_click) {}'],
                                ['click', 'function (my_button_click2) {}'],
                                ['onmouseover', 'function (my_button_onmouseover) {}']
                            ],
                            'attributes' => { 'id' => 'my-button' }
                        },
                        {
                            'tag_name'   => 'button',
                            'events'     => [
                                ['click', 'function (my_button2_click) {}']
                            ],
                            'attributes' => { 'id' => 'my-button2' }
                        }
                    ])
                end
            end

            context 'inherited events' do
                it 'returns information about all DOM elements along with their events' do
                    load 'elements_with_events/inherited'

                    expect(subject.elements_with_events).to eq([
                       { "tag_name"   => "div",
                         "events"     => [["click", "function (parent_click) {}"]],
                         "attributes" => { "id" => "parent" } },
                       { "tag_name"   => "button",
                         "events"     => [["click", "function (parent_click) {}"],
                                          ["click", "function (window_click) {}"],
                                          ["click", "function (document_click) {}"]],
                         "attributes" => { "id" => "parent-button" } },
                       { "tag_name"   => "div",
                         "events"     =>
                             [["click", "function (child_click) {}"]],
                         "attributes" => { "id" => "child" } },
                       { "tag_name"   => "button",
                         "events"     =>
                             [["click", "function (parent_click) {}"],
                              ["click", "function (child_click) {}"],
                              ["click", "function (window_click) {}"],
                              ["click", "function (document_click) {}"]],
                         "attributes" => { "id" => "child-button" } }]
                )
                end
            end
        end
    end

end
