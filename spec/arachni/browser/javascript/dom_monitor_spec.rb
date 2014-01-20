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

    describe '#timeouts' do
        it 'keeps track of setTimeout() timers' do
            load '/timeout-tracker'

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
            load '/interval-tracker'

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

end
