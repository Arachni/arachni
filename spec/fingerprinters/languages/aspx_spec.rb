require 'spec_helper'

describe Arachni::Platform::Fingerprinters::ASPX do
    include_examples 'fingerprinter'

    context 'when the page has a .aspx extension' do
        it 'identifies it as ASPX' do
            page = Arachni::Page.new( url: 'http://stuff.com/blah.aspx' )
            platforms_for( page ).should include :asp
            platforms_for( page ).should include :aspx
            platforms_for( page ).should include :windows
        end
    end

    context 'when there is a session ID in the path' do
        it 'identifies it as ASPX' do
            page = Arachni::Page.new(
                url:        'http://blah.com/(S(yn5cby55lgzstcen0ng2b4iq))/stuff'
            )
            platforms_for( page ).should include :asp
            platforms_for( page ).should include :aspx
            platforms_for( page ).should include :windows
        end
    end

    context 'when there is a ASP.NET_SessionId cookie' do
        it 'identifies it as ASPX' do
            page = Arachni::Page.new(
                url:     'http://stuff.com/blah',
                cookies: [Arachni::Cookie.new( 'http://stuff.com/blah',
                                               'ASP.NET_SessionId' => 'stuff' )]

            )
            platforms_for( page ).should include :asp
            platforms_for( page ).should include :aspx
            platforms_for( page ).should include :windows
        end
    end

    context 'when there is an X-Powered-By header' do
        it 'identifies it as ASPX' do
            page = Arachni::Page.new(
                url:     'http://stuff.com/blah',
                response_headers: { 'X-Powered-By' => 'ASP.NET'  }
            )
            platforms_for( page ).should include :asp
            platforms_for( page ).should include :aspx
            platforms_for( page ).should include :windows
        end
    end

    context 'when there is an X-AspNet-Version header' do
        it 'identifies it as ASPX' do
            page = Arachni::Page.new(
                url:     'http://stuff.com/blah',
                response_headers: { 'X-AspNet-Version' => '4.0.30319' }

            )
            platforms_for( page ).should include :asp
            platforms_for( page ).should include :aspx
            platforms_for( page ).should include :windows
        end
    end

    context 'when there is an X-AspNetMvc-Version header' do
        it 'identifies it as ASPX' do
            page = Arachni::Page.new(
                url:     'http://stuff.com/blah',
                response_headers: { 'X-AspNetMvc-Version' => '2.0' }

            )
            platforms_for( page ).should include :asp
            platforms_for( page ).should include :aspx
            platforms_for( page ).should include :windows
        end
    end

end
