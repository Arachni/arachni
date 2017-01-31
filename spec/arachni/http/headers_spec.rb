require 'spec_helper'

describe Arachni::HTTP::Headers do

    subject do
        described_class.new
    end

    describe '#merge!' do
        context 'by default' do
            context 'when it includes multiple same names that differ in case' do
                let(:cookies) do
                    {
                        'set-cookie' => 'mycookie1=myvalue1',
                        'Set-Cookie' => 'mycookie2=myvalue2',
                        'SET-COOKIE' => 'mycookie3=myvalue3'
                    }
                end

                it 'merges them into an array' do
                    subject.merge!( cookies )
                    expect(subject['set-cookie']).to eq(cookies.values)
                end
            end
        end

        context 'when convert to array is false' do
            context 'when it includes multiple same names that differ in case' do
                let(:cookies) do
                    {
                        'set-cookie' => 'mycookie1=myvalue1',
                        'Set-Cookie' => 'mycookie2=myvalue2',
                        'SET-COOKIE' => 'mycookie3=myvalue3'
                    }
                end

                it 'does not merge them into an array' do
                    subject.merge!( cookies, false )
                    expect(subject['set-cookie']).to eq(cookies.values.last)
                end
            end
        end

        context 'when convert to array is true' do
            context 'when it includes multiple same names that differ in case' do
                let(:cookies) do
                    {
                        'set-cookie' => 'mycookie1=myvalue1',
                        'Set-Cookie' => 'mycookie2=myvalue2',
                        'SET-COOKIE' => 'mycookie3=myvalue3'
                    }
                end

                it 'does not merge them into an array' do
                    subject.merge!( cookies )
                    expect(subject['set-cookie']).to eq(cookies.values)
                end
            end
        end
    end

    describe '#delete' do
        it 'deleted a header field' do
            h = described_class.new( 'x-my-field' => 'stuff' )
            expect(h.delete( 'X-My-Field' )).to eq('stuff')
        end
    end

    describe '#include?' do
        context 'when the field is included' do
            it 'returns true' do
                h = described_class.new( 'X-My-Field' => 'stuff' )
                expect(h.include?( 'x-my-field' )).to be_truthy
            end
        end
        context 'when the field is not included' do
            it 'returns false' do
                expect(described_class.new.include?( 'x-my-field' )).to be_falsey
            end
        end
    end

    describe 'set_cookie' do
        context 'when there are no set-cookie fields' do
            it 'returns an empty array' do
                expect(described_class.new.cookies).to eq([])
            end
        end

        it 'returns an array of set-cookie strings' do
            set_coookies = [
                'name=value; Expires=Wed, 09 Jun 2020 10:18:14 GMT',
                'name2=value2; Expires=Wed, 09 Jun 2021 10:18:14 GMT'
            ]

            expect(described_class.new( 'Set-Cookie' => set_coookies ).set_cookie).to eq(set_coookies)
        end
    end

    describe 'cookies' do
        context 'when there are no cookies' do
            it 'returns an empty array' do
                expect(described_class.new.cookies).to eq([])
            end
        end

        it 'returns an array of cookies as hashes' do
            expect(described_class.new(
                'Set-Cookie' => [
                    'name=value; Expires=Wed, 09 Jun 2020 10:18:14 GMT',
                    'name2=value2; Expires=Wed, 09 Jun 2021 10:18:14 GMT'
                ]
            ).cookies).to eq([
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
            ])
        end
    end

    describe '#location' do
        it 'returns the Location' do
            ct = 'http://test.com'
            h = { 'location' => ct }
            expect(described_class.new( h ).location).to eq(ct)

            h = { 'Location' => ct }
            expect(described_class.new( h ).location).to eq(ct)
        end
    end

    describe '#content_type' do
        it 'returns the content-type' do
            ct = 'text/html'
            h = { 'content-type' => ct }
            expect(described_class.new( h ).content_type).to eq(ct)

            h = { 'Content-Type' => ct }
            expect(described_class.new( h ).content_type).to eq(ct)
        end

        context 'when there are multiple content-types' do
            it 'returns the first one' do
                h = { 'Content-Type' =>  ["application/x-javascript", "text/javascript"] }
                expect(described_class.new( h ).content_type).to eq("application/x-javascript")
            end
        end
    end
end
