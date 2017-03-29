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
            expect(subject.digest).to eq(1754753071)

            # expect(subject.digest).to eq('<HTML><HEAD><SCRIPT src=http://' <<
            #     'javascript.browser.arachni/polyfills.js><SCRIPT src=http://javascri' <<
            #     'pt.browser.arachni/' <<'taint_tracer.js><SCRIPT src' <<
            #     '=http://javascript.browser.arachni/dom_monitor.js><SCRIPT>' <<
            #     '<BODY onload=void();><DIV id=my-id-div><DIV class=my-class' <<
            #     '-div><STRONG><EM><I><B><STRONG><SCRIPT><SCRIPT type=text/' <<
            #     'javascript><A href=#stuff>')
        end

        it 'does not include <p> elements' do
            load '/digest/p'
            expect(subject.digest).to eq(422148765)

            # expect(subject.digest).to eq('<HTML><HEAD><SCRIPT src=http://' <<
            #     'javascript.browser.arachni/polyfills.js><SCRIPT src=http://javascript' <<
            #     '.browser.arachni/taint_tracer.js><SCRIPT src=http://' <<
            #     'javascript.browser.arachni/dom_monitor.js><SCRIPT><BODY><STRONG>')
        end

        it "does not include 'data-arachni-id' attributes" do
            load '/digest/data-arachni-id'
            expect(subject.digest).to eq(822535290)

            # expect(subject.digest).to eq('<HTML><HEAD><SCRIPT src=http://' <<
            #     'javascript.browser.arachni/polyfills.js><SCRIPT src=http://javascript' <<
            #     '.browser.arachni/taint_tracer.js><SCRIPT src=http://' <<
            #     'javascript.browser.arachni/dom_monitor.js><SCRIPT><BODY><DIV ' <<
            #     'id=my-id-div><DIV class=my-class-div>')
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

    describe '#elements_with_events' do
        it 'skips non visible elements' do
            load '/elements_with_events/with-hidden'

            expect(subject.elements_with_events).to eq([
                {
                    'tag_name' => 'button',
                    'events' => {
                        'click' =>  [
                            'function (my_button_click) {}',
                            'handler_1()'
                        ]
                    },
                    'attributes' => {
                        'onclick' => 'handler_1()',
                        'id' => 'my-button'
                    }
                }
            ])
        end

        context 'when given a whitelist of tag names' do
            it 'only returns those types of elements' do
                load '/elements_with_events/whitelist'

                expect(subject.elements_with_events( 0, 100, ['span'] )).to eq([
                    {
                        'tag_name'   => 'span',
                        'events'     =>
                            {
                                'click' => [
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

        context 'when it has a dot delimited custom event' do
            it 'retains the first part' do
                load '/elements_with_events/custom-dot-delimited'

                expect(subject.elements_with_events).to eq([
                    {
                        "tag_name"   => "button",
                        "events"     => {
                            "click"=> [
                                "function (e) {\n\t\t\t\t// Discard the second event of a jQuery.event.trigger() and\n\t\t\t\t// when an event is called after a page has unloaded\n\t\t\t\treturn typeof jQuery !== core_strundefined && (!e || jQuery.event.triggered !== e.type) ?\n\t\t\t\t\tjQuery.event.dispatch.apply( eventHandle.elem, arguments ) :\n\t\t\t\t\tundefined;\n\t\t\t}"
                            ]
                        },
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
                            'events'     => {
                                'click' => ['handler_1()']
                            },
                            'attributes' => { 'onclick' => 'handler_1()', 'id' => 'my-button' }
                        },
                        {
                            'tag_name'   => 'button',
                            'events'     => {
                                'click' => ['handler_2()']
                            },
                            'attributes' => { 'onclick' => 'handler_2()', 'id' => 'my-button2' }
                         },
                         {
                             'tag_name' => 'button',
                             'events'     => {
                                 'click' => ['handler_3()']
                             },
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
                            'events'     => {
                                'click' => [
                                    'function (my_button_click) {}',
                                    'function (my_button_click2) {}'
                                ],
                                'mouseover' => ['function (my_button_onmouseover) {}']
                            },
                            'attributes' => { 'id' => 'my-button' }
                        },
                        {
                            'tag_name'   => 'button',
                            'events'     => {
                                'click' => ['function (my_button2_click) {}']
                            },
                            'attributes' => { 'id' => 'my-button2' }
                        }
                    ])
                end
            end

            context 'inherited events' do
                it 'returns information about all DOM elements along with their events' do
                    load 'elements_with_events/inherited'

                    expect(subject.elements_with_events).to eq([
                        {
                           "tag_name"   => "div",
                           "events"     => {
                               "click" => [
                                   "function (parent_click) {}"
                               ]
                           },
                           "attributes" => { "id" => "parent" } },
                        {
                           "tag_name"   => "button",
                           "events"     => {
                               "click" => [
                                   "function (parent_click) {}",
                                   "function (window_click) {}",
                                   "function (document_click) {}"
                               ]
                           },
                           "attributes" => { "id" => "parent-button" }
                        },
                        {
                           "tag_name"   => "div",
                           "events"     => {
                               "click" => ["function (child_click) {}"]
                           },
                           "attributes" => { "id" => "child" }
                        },
                        {
                           "tag_name"   => "button",
                           "events"     => {
                               "click" => [
                                   "function (parent_click) {}",
                                   "function (child_click) {}",
                                   "function (window_click) {}",
                                   "function (document_click) {}"
                               ]
                           },
                           "attributes" => { "id" => "child-button" }
                        }
                    ])
                end
            end
        end
    end

    describe '#event_digest' do
        before(:each) do
            @url = Arachni::Utilities.normalize_url( web_server_url_for( :browser ) )

            @empty_event_digest ||= begin
                @browser.load( empty_event_digest_url )
                subject.event_digest
            end

            @browser.load( url )
            @event_digest = subject.event_digest
        end

        let(:empty_event_digest_url) { @url + '/event_digest/default' }
        let(:empty_event_digest) do
            @empty_event_digest
        end
        let(:event_digest) do
            @event_digest
        end

        let(:url) { @url + '/trigger_events' }

        it 'returns a DOM digest' do
            expect(event_digest).to eq(subject.event_digest)
        end

        context 'when there are new cookies' do
            let(:url) { @url + '/each_element_with_events/set-cookie' }

            it 'takes them into account' do
                @browser.fire_event Arachni::Browser::ElementLocator.new(
                    tag_name: :button,
                    attributes: {
                        onclick: 'setCookie()'
                    }
                ), :click

                expect(subject.event_digest).not_to eq(event_digest)
            end
        end

        context ':a' do
            context 'and the href is not empty' do
                context 'and it starts with javascript:' do
                    let(:url) { @url + '/each_element_with_events/a/href/javascript' }

                    it 'takes it into account' do
                        expect(event_digest).not_to eq(empty_event_digest)
                    end
                end

                context 'and it does not start with javascript:' do
                    let(:url) { @url + '/each_element_with_events/a/href/regular' }

                    it 'takes it into account' do
                        expect(event_digest).not_to eq(empty_event_digest)
                    end
                end
            end

            context 'and the href is empty' do
                let(:url) { @url + '/each_element_with_events/a/href/empty' }

                it 'takes it into account' do
                    expect(event_digest).not_to eq(empty_event_digest)
                end
            end
        end

        context ':form' do
            let(:empty_event_digest_url) { @url + '/event_digest/form/default' }

            context ':input' do
                context 'of type "image"' do
                    let(:url) { @url + '/each_element_with_events/form/input/image' }

                    it 'takes it into account' do
                        expect(event_digest).not_to eq(empty_event_digest)
                    end
                end
            end

            context 'and the action is not empty' do
                context 'and it starts with javascript:' do
                    let(:url) { @url + '/each_element_with_events/form/action/javascript' }

                    it 'takes it into account' do
                        expect(event_digest).not_to eq(empty_event_digest)
                    end
                end

                context 'and it does not start with javascript:' do
                    let(:url) { @url + '/each_element_with_events/form/action/regular' }

                    it 'takes it into account' do
                        expect(event_digest).not_to eq(empty_event_digest)
                    end
                end
            end
        end
    end
end
