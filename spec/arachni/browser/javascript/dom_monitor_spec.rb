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

    describe '#initialized' do
        it 'returns true' do
            subject.initialized.should be_true
        end
    end

    it 'adds .events property to elements holding the tracked events' do
        load '/events'

        javascript.run( "return document.getElementById('my-button').events").should == [
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
        ]

        javascript.run( "return document.getElementById('my-button2').events").should == [
            [
                'click',
                'function (my_button2_click) {}'
            ]
        ]

        javascript.run( "return document.getElementById('my-button3').events").should be_nil
    end

    describe '#digest' do
        it 'returns a string digest of the current DOM tree' do
            load '/digest'
            subject.digest.should ==
                '<HTML><HEAD><SCRIPT src=http://javascript.browser.arachni/tai' +
                    'nt_tracer.js><SCRIPT><SCRIPT src=http://javascript.browser.' +
                    'arachni/dom_monitor.js><SCRIPT><BODY onload=void();><DIV ' +
                    'id=my-id-div><DIV class=my-class-div><STRONG><EM><I><B>' +
                    '<STRONG><SCRIPT><A href=#stuff>'
        end
    end

    describe '#timeouts' do
        it 'keeps track of setTimeout() timers' do
            load '/timeouts'

            subject.timeouts.should == [
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
            load '/intervals'

            subject.intervals.should == [
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

    describe '#elements_with_events' do
        it 'returns information about all DOM elements along with their events' do
            load '/events'

            subject.elements_with_events.should == [
                { 'tag_name' => 'html', 'events' => [], 'attributes' => {}
                },
                {
                    'tag_name' => 'body', 'events' => [], 'attributes' => {}
                },
                {
                    'tag_name'   => 'button',
                    'events'     => [
                        ['click', 'function (my_button_click) {}'],
                        ['click', 'function (my_button_click2) {}'],
                        ['onmouseover', 'function (my_button_onmouseover) {}']
                    ],
                    'attributes' => { 'id' => 'my-button' } },
                {
                    'tag_name'   => 'button',
                    'events'     => [
                        ['click', 'function (my_button2_click) {}']
                    ],
                    'attributes' => { 'id' => 'my-button2' }
                 },
                 {
                     'tag_name' => 'button',
                     'events' => [],
                     'attributes' => { 'id' => 'my-button3' }
                 }
            ]
        end

        it 'skips non visible elements'
    end

end
