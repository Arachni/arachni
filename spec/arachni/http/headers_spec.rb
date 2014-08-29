require 'spec_helper'

describe Arachni::HTTP::Headers do
    describe '#delete' do
        it 'deleted a header field' do
            h = described_class.new( 'x-my-field' => 'stuff' )
            h.delete( 'X-My-Field' ).should == 'stuff'
        end
    end

    describe '#include?' do
        context 'when the field is included' do
            it 'returns true' do
                h = described_class.new( 'X-My-Field' => 'stuff' )
                h.include?( 'x-my-field' ).should be_true
            end
        end
        context 'when the field is not included' do
            it 'returns false' do
                described_class.new.include?( 'x-my-field' ).should be_false
            end
        end
    end

    describe 'set_cookie' do
        context 'when there are no set-cookie fields' do
            it 'returns an empty array' do
                described_class.new.cookies.should == []
            end
        end

        it 'returns an array of set-cookie strings' do
            set_coookies = [
                'name=value; Expires=Wed, 09 Jun 2020 10:18:14 GMT',
                'name2=value2; Expires=Wed, 09 Jun 2021 10:18:14 GMT'
            ]

            described_class.new( 'Set-Cookie' => set_coookies ).set_cookie.should == set_coookies
        end
    end

    describe 'cookies' do
        context 'when there are no cookies' do
            it 'returns an empty array' do
                described_class.new.cookies.should == []
            end
        end

        it 'returns an array of cookies as hashes' do
            described_class.new(
                'Set-Cookie' => [
                    'name=value; Expires=Wed, 09 Jun 2020 10:18:14 GMT',
                    'name2=value2; Expires=Wed, 09 Jun 2021 10:18:14 GMT'
                ]
            ).cookies.should == [
                {
                    name:         'name',
                    value:        'value',
                    version:      0,
                    port:         nil,
                    discard:      nil,
                    comment_url:  nil,
                    expires:      Time.parse( '2020-06-09 13:18:14 +0300' ),
                    max_age:      nil,
                    comment:      nil,
                    secure:       nil,
                    path:         nil,
                    domain:       nil,
                    httponly:     false
                },
                {
                    name:         'name2',
                    value:        'value2',
                    version:      0,
                    port:         nil,
                    discard:      nil,
                    comment_url:  nil,
                    expires:      Time.parse( '2021-06-09 13:18:14 +0300' ),
                    max_age:      nil,
                    comment:      nil,
                    secure:       nil,
                    path:         nil,
                    domain:       nil,
                    httponly:     false
                }
            ]
        end
    end

    describe '#location' do
        it 'returns the content-type' do
            ct = 'http://test.com'
            h = { 'location' => ct }
            described_class.new( h ).location.should == ct

            h = { 'Location' => ct }
            described_class.new( h ).location.should == ct
        end
    end

    describe '#content_type' do
        it 'returns the content-type' do
            ct = 'text/html'
            h = { 'content-type' => ct }
            described_class.new( h ).content_type.should == ct

            h = { 'Content-Type' => ct }
            described_class.new( h ).content_type.should == ct
        end
    end
end
