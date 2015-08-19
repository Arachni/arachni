require 'spec_helper'

describe Arachni::Platform::Fingerprinter do

    describe '#page' do
        it 'returns the given page' do
            page = Arachni::Page.new( url: 'http://test/' )
            expect(described_class.new( page ).page).to eq(page)
        end
    end

    describe '#parameters' do
        it 'returns the downcased page parameters' do
            page = Arachni::Page.new( url: 'http://stuff.com/?A=B&C=D' )
            expect(described_class.new( page ).parameters).to eq(
                { 'a' => 'b', 'c' => 'd' }
            )
        end
    end

    describe '#cookies' do
        it 'returns the downcased cookies' do
            page = Arachni::Page.new(
                url: 'http://stuff.com/?A=B',
                cookies: [ Arachni::Cookie.new(
                               url:    'http://stuff.com/?A=B',
                               inputs: { 'nAmE' => 'vAlUe' }
                           )]
            )
            expect(described_class.new( page ).cookies).to eq(
                { 'name' => 'value' }
            )
        end
    end

    describe '#headers' do
        it 'returns the downcased headers' do
            page = Arachni::Page.from_data(
                url: 'http://stuff.com/?A=B',
                response: { headers: { 'nAmE' => 'vAlUe' } }
            )
            expect(described_class.new( page ).headers).to eq(
                { 'name' => 'value' }
            )
        end
    end

    describe '#powered_by' do
        it 'returns the value of the X-Powered-By header' do
            page = Arachni::Page.from_data(
                url: 'http://stuff.com/?A=B',
                response: { headers: { 'x-PowEred-BY' => 'UberServer' } }

            )
            expect(described_class.new( page ).powered_by).to eq('uberserver')
        end
    end

    describe '#server' do
        it 'returns the value of the X-Powered-By header' do
            page = Arachni::Page.from_data(
                url: 'http://stuff.com/?A=B',
                response: { headers: { 'SeRvEr' => 'UberServer' } }
            )
            expect(described_class.new( page ).server).to eq('uberserver')
        end
    end

    describe '#extension' do
        it 'returns the file extension of the page resource' do
            page = Arachni::Page.from_data( url: 'http://stuff.com/blah.stuff/page.pHp' )
            expect(described_class.new( page ).extension).to eq('php')
        end
    end

    describe '#platforms' do
        it 'returns platforms of the page' do
            page = Arachni::Page.from_data(
                url: 'http://stuff.com/?A=B',
                response: { headers: { 'SeRvEr' => 'UberServer' } }
            )
            expect(described_class.new( page ).platforms).to eq(page.platforms)
        end
    end

    describe '#server_or_powered_by_include?' do
        context 'when the Server header contains the given string' do
            it 'returns true' do
                page = Arachni::Page.from_data(
                    url: 'http://stuff.com/?A=B',
                    response: { headers: { 'SeRvEr' => 'UberServer/32' } }
                )
                expect(described_class.new( page ).server_or_powered_by_include?( 'uberserver' )).to be_truthy
            end
        end
        context 'when the X-Powered-By header contains the given string' do
            it 'returns true' do
                page = Arachni::Page.from_data(
                    url: 'http://stuff.com/?A=B',
                    response: { headers: { 'X-Powered-By' => 'UberServer/32' } }
                )
                expect(described_class.new( page ).server_or_powered_by_include?( 'uberserver' )).to be_truthy
            end
        end
        context 'when both the Server or X-Powered-By header contain the given string' do
            it 'returns true' do
                page = Arachni::Page.from_data(
                    url: 'http://stuff.com/?A=B',
                    response: {
                        headers: {
                            'X-Powered-By' => 'UberServer/32',
                            'Server' => 'UberServer/32',
                        }
                    }
                )
                expect(described_class.new( page ).server_or_powered_by_include?( 'uberserver' )).to be_truthy
            end
        end
        context 'when the Server header does not contain the given string' do
            it 'returns true' do
                page = Arachni::Page.from_data(
                    url: 'http://stuff.com/?A=B',
                    response: {
                        headers: {
                            'SeRvEr' => 'Server/32'
                        }
                    }
                )
                expect(described_class.new( page ).server_or_powered_by_include?( 'uberserver' )).to be_falsey
            end
        end
        context 'when the X-Powered-By header does not contain the given string' do
            it 'returns true' do
                page = Arachni::Page.from_data(
                    url: 'http://stuff.com/?A=B',
                    response: {
                        headers: {
                            'X-Powered-By' => 'Server/32'
                        }
                    }
                )
                expect(described_class.new( page ).server_or_powered_by_include?( 'uberserver' )).to be_falsey
            end
        end
        context 'when the X-Powered-By header does not contain the given string' do
            it 'returns true' do
                page = Arachni::Page.from_data(
                    url: 'http://stuff.com/?A=B',
                    response: {
                        headers: {
                            'Server' => 'Server/32',
                            'X-Powered-By' => 'Server/32'
                        }
                    }
                )
                expect(described_class.new( page ).server_or_powered_by_include?( 'uberserver' )).to be_falsey
            end
        end
    end

end
