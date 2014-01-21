require 'spec_helper'

describe Arachni::Browser::Javascript::Proxy::Stub do

    before( :all ) do
        @url = Arachni::Utilities.normalize_url( web_server_url_for( :proxy ) )
    end

    before( :each ) do
        @browser    = Arachni::Browser.new
        @javascript = @browser.javascript
        @proxy      = Arachni::Browser::Javascript::Proxy.new( @javascript, 'ProxyTest' )

        @browser.load "#{@url}?token=#{@javascript.token}"
    end

    after( :each ) do
        @browser.shutdown
    end

    subject do
        described_class.new( Arachni::Browser::Javascript::Proxy.new( @javascript, 'ProxyTest' ) )
    end
    let(:data) { { 'test' => [1,'2'] } }

    it 'writes property getters' do
        subject.my_property.should == "#{@proxy.js_object}.my_property"
    end

    it 'writes function calls' do
        subject.my_function( data ).should ==
            "#{@proxy.js_object}.my_function(#{data.to_json})"
    end

    describe '#property' do
        it 'writes property getters' do
            subject.property(:my_property).should == "#{@proxy.js_object}.my_property"
        end
    end

    describe '#function' do
        it 'writes function calls' do
            subject.function(:my_function, data).should ==
                "#{@proxy.js_object}.my_function(#{data.to_json})"
        end

        it 'writes property setters' do
            subject.function(:my_property=, 3).should == "#{@proxy.js_object}.my_property=3"
        end
    end

    describe '#write' do
        it 'writes property getters' do
            subject.write(:my_property).should == "#{@proxy.js_object}.my_property"
        end

        it 'writes property setters' do
            subject.write(:my_property=, 3).should == "#{@proxy.js_object}.my_property=3"
        end

        it 'writes function calls' do
            subject.write(:my_function, data).should ==
                "#{@proxy.js_object}.my_function(#{data.to_json})"
        end

        it 'automatically detects function calls' do
            subject.write(:my_function).should == "#{@proxy.js_object}.my_function()"
        end
    end

    describe '#respond_to?' do
        context 'when the JS object supports the given' do
            context 'property' do
                it 'returns true' do
                    subject.respond_to?(:my_property).should be_true
                end

                context 'setter' do
                    it 'returns true' do
                        subject.respond_to?(:my_property=).should be_true
                    end
                end
            end

            context 'function' do
                it 'returns true' do
                    subject.respond_to?(:my_function).should be_true
                end
            end
        end

        context 'when the JS object does not support the given' do
            context 'property' do
                it 'returns true' do
                    subject.respond_to?(:my_stuff).should be_false
                end

                context 'setter' do
                    it 'returns true' do
                        subject.respond_to?(:my_stuff=).should be_false
                    end
                end
            end
        end
    end
end
