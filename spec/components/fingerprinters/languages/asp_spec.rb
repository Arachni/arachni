require 'spec_helper'

describe Arachni::Platform::Fingerprinters::ASP do
    include_examples 'fingerprinter'

    def platforms
        [:asp, :windows]
    end

    context 'when the page has a .asp extension' do
        it 'identifies it as ASP' do
            check_platforms Arachni::Page.from_data( url: 'http://stuff.com/blah.asp' )
        end
    end

    context 'when there is a ASPSESSIONID query parameter' do
        it 'identifies it as ASP' do
            check_platforms Arachni::Page.from_data(
                url: 'http://stuff.com/blah?ASPSESSIONID=stuff'
            )
        end
    end

    context 'when there is a ASPSESSIONID cookie' do
        it 'identifies it as ASP' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                cookies: [Arachni::Cookie.new(
                              url:    'http://stuff.com/blah',
                              inputs: { 'ASPSESSIONID' => 'stuff' } )]

            )
        end
    end

end
