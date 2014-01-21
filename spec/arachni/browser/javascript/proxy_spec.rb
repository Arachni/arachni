require 'spec_helper'

describe Arachni::Browser::Javascript::Proxy do

    before( :all ) do
        @url = Arachni::Utilities.normalize_url( web_server_url_for( :proxy ) )
    end

    before( :each ) do
        @browser      = Arachni::Browser.new
        @javascript   = @browser.javascript
        @browser.load "#{@url}?token=#{@javascript.token}"
    end

    after( :each ) do
        @browser.shutdown
    end

    subject { described_class.new @javascript, 'ProxyTest' }
    let(:data) { { 'test' => [1,'2'] } }

    it 'accesses properties' do
        subject.my_property.should be_nil
    end

    it 'sets properties' do
        subject.my_property = data
        subject.my_property.should == data
    end

    it 'calls functions' do
        subject.my_function.should == [nil, nil, nil]
        subject.my_function( 1, '2', data ).should == [1, '2', data]
    end

    describe '#stub' do
        it 'returns the Stub instance' do
            subject.stub.to_s.should end_with 'ProxyTest>'
        end
    end

    describe '#javascript' do
        it 'returns the Javascript instance' do
            subject.javascript.should be_kind_of Arachni::Browser::Javascript
        end
    end

    describe '#js_object' do
        it 'returns the JS-side object of the proxied object' do
            subject.js_object.should == "_#{@javascript.token}ProxyTest"

            js_object = @javascript.run( "return #{subject.js_object}" )
            js_object.should include 'my_property'
            js_object['my_function'].should start_with 'function ('
        end
    end

    describe '#function?' do
        context 'when dealing with setters' do
            context 'for existing properties' do
                it 'returns true' do
                    subject.function?( :my_function= ).should be_true
                    subject.function?( :my_property= ).should be_true
                end
            end

            context 'for nonexistent properties' do
                it 'returns false' do
                    subject.function?( :stuff= ).should be_false
                end
            end
        end

        context 'when the specified property is a function' do
            it 'returns true' do
                subject.function?( :my_function ).should be_true
            end
        end

        context 'when the specified property is not a function' do
            it 'returns false' do
                subject.function?( :my_property ).should be_false
            end
        end
    end

    describe '#call' do
        it 'accesses properties' do
            subject.call(:my_property).should be_nil
        end

        it 'sets properties' do
            subject.call(:my_property=, data)
            subject.call(:my_property).should == data
        end

        it 'calls functions' do
            subject.call(:my_function).should == [nil, nil, nil]
            subject.call(:my_function, 1, '2', data ).should == [1, '2', data]
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
