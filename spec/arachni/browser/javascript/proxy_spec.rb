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
        expect(subject.my_property).to be_nil
    end

    it 'sets properties' do
        subject.my_property = data
        expect(subject.my_property).to eq(data)
    end

    it 'calls functions' do
        expect(subject.my_function).to eq([nil, nil, nil])
        expect(subject.my_function( 1, '2', data )).to eq([1, '2', data])
    end

    describe '#class' do
        it "returns #{described_class}" do
            expect(subject.class).to eq(described_class)
        end
    end

    describe '#stub' do
        it 'returns the Stub instance' do
            expect(subject.stub.to_s).to end_with 'ProxyTest>'
        end
    end

    describe '#javascript' do
        it 'returns the Javascript instance' do
            expect(subject.javascript).to be_kind_of Arachni::Browser::Javascript
        end
    end

    describe '#js_object' do
        it 'returns the JS-side object of the proxied object' do
            expect(subject.js_object).to eq("_#{@javascript.token}ProxyTest")

            js_object = @javascript.run( "return #{subject.js_object}" )
            expect(js_object).to include 'my_property'
            expect(js_object['my_function']).to start_with 'function ('
        end
    end

    describe '#function?' do
        context 'when dealing with setters' do
            context 'for existing properties' do
                it 'returns true' do
                    expect(subject.function?( :my_function= )).to be_truthy
                    expect(subject.function?( :my_property= )).to be_truthy
                end
            end

            context 'for nonexistent properties' do
                it 'returns false' do
                    expect(subject.function?( :stuff= )).to be_falsey
                end
            end
        end

        context 'when the specified property is a function' do
            it 'returns true' do
                expect(subject.function?( :my_function )).to be_truthy
            end
        end

        context 'when the specified property is not a function' do
            it 'returns false' do
                expect(subject.function?( :my_property )).to be_falsey
            end
        end
    end

    describe '#call' do
        it 'accesses properties' do
            expect(subject.call(:my_property)).to be_nil
        end

        it 'sets properties' do
            subject.call(:my_property=, data)
            expect(subject.call(:my_property)).to eq(data)
        end

        it 'calls functions' do
            expect(subject.call(:my_function)).to eq([nil, nil, nil])
            expect(subject.call(:my_function, 1, '2', data )).to eq([1, '2', data])
        end
    end

    describe '#respond_to?' do
        context 'when the JS object supports the given' do
            context 'property' do
                it 'returns true' do
                    expect(subject.respond_to?(:my_property)).to be_truthy
                end

                context 'setter' do
                    it 'returns true' do
                        expect(subject.respond_to?(:my_property=)).to be_truthy
                    end
                end
            end

            context 'function' do
                it 'returns true' do
                    expect(subject.respond_to?(:my_function)).to be_truthy
                end
            end
        end

        context 'when the JS object does not support the given' do
            context 'property' do
                it 'returns true' do
                    expect(subject.respond_to?(:my_stuff)).to be_falsey
                end

                context 'setter' do
                    it 'returns true' do
                        expect(subject.respond_to?(:my_stuff=)).to be_falsey
                    end
                end
            end
        end
    end
end
