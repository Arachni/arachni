require 'spec_helper'

describe Arachni::HTTP::Response do
    it_should_behave_like 'Arachni::HTTP::Message'

    describe '#redirection?' do
        context 'when the response is a redirection' do
            it 'returns true' do
                300.upto( 399 ) do |c|
                    described_class.new(
                        url:     'http://test.com',
                        code:    c,
                        headers: {
                            location: '/test'
                        }).redirection?.should be_true
                end
            end
        end

        context 'when the response is not a redirection' do
            it 'returns false' do
                described_class.new( 'http://test.com', code: 200 ).redirection?.should be_false
            end
        end
    end

    describe '#text?' do
        context 'when the content-type is' do
            context 'text/*' do
                it 'returns true' do
                    h = {
                        headers: { 'Content-Type' => 'text/stuff' },
                        body:    'stuff'
                    }
                    described_class.new( 'http://test.com', h ).text?.should be_true
                end
            end

            context 'application/*' do
                context 'and the response body is' do
                    context 'binary' do
                        it 'returns false' do
                            h = {
                                headers: { 'Content-Type' => 'application/stuff' },
                                body:    "\00\00\00"
                            }
                            described_class.new( 'http://test.com', h ).text?.should be_false
                        end
                    end

                    context 'text' do
                        it 'returns true' do
                            h = {
                                headers: { 'Content-Type' => 'application/stuff' },
                                body:    'stuff'
                            }
                            described_class.new( 'http://test.com', h ).text?.should be_true
                        end
                    end
                end
            end

            context 'other' do
                it 'returns false' do
                    h = {
                        headers: { 'Content-Type' => 'blah/stuff' },
                        body:    'stuff'
                    }
                    described_class.new( 'http://test.com', h ).text?.should be_false
                end
            end

            context nil do
                context 'and the response body is' do
                    context 'binary' do
                        it 'returns false' do
                            h = { body: "\00\00\00" }
                            described_class.new( 'http://test.com', h ).text?.should be_false
                        end
                    end

                    context 'text' do
                        it 'returns true' do
                            h = { body: 'stuff' }
                            described_class.new( 'http://test.com', h ).text?.should be_true
                        end
                    end
                end
            end
        end
    end

    describe '#to_h' do
        it 'returns a hash representation of self' do
            h = {
                version:        '1.1',
                url:            'http://stuff.com',
                code:           200,
                ip_address:     '10.0.0.1',
                headers:        { 'Content-Type' => 'test/html' },
                headers_string: 'HTTP/1.1 200 OK',
                body:           'stuff',
                time:           1.2,
                total_time:     2.2,
                return_code:    :ok,
                return_message: 'No error'
            }

            described_class.new( h ).to_h.should == h.stringify_keys
        end
    end

end
