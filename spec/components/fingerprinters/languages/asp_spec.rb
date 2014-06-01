require 'spec_helper'

describe Arachni::Platform::Fingerprinters::ASP do
    include_examples 'fingerprinter'

    context 'when the page has a .asp extension' do
        it 'identifies it as ASP' do
            page = Arachni::Page.from_data( url: 'http://stuff.com/blah.asp' )
            platforms_for( page ).should include :asp
            platforms_for( page ).should include :windows
        end
    end

    context 'when there is a ASPSESSIONID query parameter' do
        it 'identifies it as ASP' do
            page = Arachni::Page.from_data(
                url: 'http://stuff.com/blah?ASPSESSIONID=stuff'
            )
            platforms_for( page ).should include :asp
            platforms_for( page ).should include :windows
        end
    end

    context 'when there is a ASPSESSIONID cookie' do
        it 'identifies it as ASP' do
            page = Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                cookies: [Arachni::Cookie.new(
                              url:    'http://stuff.com/blah',
                              inputs: { 'ASPSESSIONID' => 'stuff' } )]

            )
            platforms_for( page ).should include :asp
            platforms_for( page ).should include :windows
        end
    end

end
