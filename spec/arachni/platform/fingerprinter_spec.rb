require 'spec_helper'

describe Arachni::Platform::Fingerprinter do

    describe '#page' do
        it 'returns the given page' do
            page = Arachni::Page.new
            described_class.new( page ).page.should == page
        end
    end

    describe '#parameters' do
        it 'returns the downcased page parameters' do
            page = Arachni::Page.new(
                url: 'http://stuff.com?A=B',
                query_vars: {
                    'A' => 'B',
                    'C' => 'D'
                }
            )
            described_class.new( page ).parameters.should ==
                { 'a' => 'b', 'c' => 'd' }
        end
    end

    describe '#cookies' do
        it 'returns the downcased cookies' do
            page = Arachni::Page.new(
                url: 'http://stuff.com?A=B',
                cookies: [ Arachni::Cookie.new(
                               'http://stuff.com?A=B',
                               { 'nAmE' => 'vAlUe' }
                           )]
            )
            described_class.new( page ).cookies.should ==
                { 'name' => 'value' }
        end
    end

    describe '#headers' do
        it 'returns the downcased headers' do
            page = Arachni::Page.new(
                url: 'http://stuff.com?A=B',
                response_headers: { 'nAmE' => 'vAlUe' }
            )
            described_class.new( page ).headers.should ==
                { 'name' => 'value' }
        end
    end

    describe '#powered_by' do
        it 'returns the value of the X-Powered-By header' do
            page = Arachni::Page.new(
                url: 'http://stuff.com?A=B',
                response_headers: { 'x-PowEred-BY' => 'UberServer' }
            )
            described_class.new( page ).powered_by.should == 'uberserver'
        end
    end

    describe '#server' do
        it 'returns the value of the X-Powered-By header' do
            page = Arachni::Page.new(
                url: 'http://stuff.com?A=B',
                response_headers: { 'SeRvEr' => 'UberServer' }
            )
            described_class.new( page ).server.should == 'uberserver'
        end
    end

    describe '#extension' do
        it 'returns the file extension of the page resource' do
            page = Arachni::Page.new( url: 'http://stuff.com/blah.stuff/page.pHp' )
            described_class.new( page ).extension.should == 'php'
        end
    end

    describe '#platforms' do
        it 'returns platforms of the page' do
            page = Arachni::Page.new(
                url: 'http://stuff.com?A=B',
                response_headers: { 'SeRvEr' => 'UberServer' }
            )
            described_class.new( page ).platforms.should == page.platforms
        end
    end

    describe '#server_or_powered_by_include?' do
        context 'when the Server header contains the given string' do
            it 'returns true' do
                page = Arachni::Page.new(
                    url: 'http://stuff.com?A=B',
                    response_headers: {
                        'SeRvEr' => 'UberServer/32'
                    }
                )
                described_class.new( page ).server_or_powered_by_include?( 'uberserver' ).should be_true
            end
        end
        context 'when the X-Powered-By header contains the given string' do
            it 'returns true' do
                page = Arachni::Page.new(
                    url: 'http://stuff.com?A=B',
                    response_headers: {
                        'X-Powered-By' => 'UberServer/32'
                    }
                )
                described_class.new( page ).server_or_powered_by_include?( 'uberserver' ).should be_true
            end
        end
        context 'when both the Server or X-Powered-By header contain the given string' do
            it 'returns true' do
                page = Arachni::Page.new(
                    url: 'http://stuff.com?A=B',
                    response_headers: {
                        'X-Powered-By' => 'UberServer/32',
                        'Server' => 'UberServer/32',
                    }
                )
                described_class.new( page ).server_or_powered_by_include?( 'uberserver' ).should be_true
            end
        end
        context 'when the Server header does not contain the given string' do
            it 'returns true' do
                page = Arachni::Page.new(
                    url: 'http://stuff.com?A=B',
                    response_headers: {
                        'SeRvEr' => 'Server/32'
                    }
                )
                described_class.new( page ).server_or_powered_by_include?( 'uberserver' ).should be_false
            end
        end
        context 'when the X-Powered-By header does not contain the given string' do
            it 'returns true' do
                page = Arachni::Page.new(
                    url: 'http://stuff.com?A=B',
                    response_headers: {
                        'X-Powered-By' => 'Server/32'
                    }
                )
                described_class.new( page ).server_or_powered_by_include?( 'uberserver' ).should be_false
            end
        end
        context 'when the X-Powered-By header does not contain the given string' do
            it 'returns true' do
                page = Arachni::Page.new(
                    url: 'http://stuff.com?A=B',
                    response_headers: {
                        'Server' => 'Server/32',
                        'X-Powered-By' => 'Server/32'
                    }
                )
                described_class.new( page ).server_or_powered_by_include?( 'uberserver' ).should be_false
            end
        end
    end

end
