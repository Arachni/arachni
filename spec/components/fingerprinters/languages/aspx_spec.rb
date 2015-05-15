require 'spec_helper'

describe Arachni::Platform::Fingerprinters::ASPX do
    include_examples 'fingerprinter'

    def platforms
        [:asp, :aspx, :windows]
    end

    context 'when the page has a .aspx extension' do
        it 'identifies it as ASPX' do
            check_platforms Arachni::Page.from_data( url: 'http://stuff.com/blah.aspx' )
        end
    end

    context 'when there is a session ID in the path' do
        it 'identifies it as ASPX' do
            check_platforms Arachni::Page.from_data(
                url:        'http://blah.com/(S(yn5cby55lgzstcen0ng2b4iq))/stuff'
            )
        end
    end

    context 'when there is a ASP.NET_SessionId cookie' do
        it 'identifies it as ASPX' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                cookies: [Arachni::Cookie.new(
                              url:  'http://stuff.com/blah',
                              inputs: { 'ASP.NET_SessionId' => 'stuff' } )]

            )
        end
    end

    context 'when there is an X-Powered-By header' do
        it 'identifies it as ASPX' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'X-Powered-By' => 'ASP.NET'  } }
            )
        end
    end

    context 'when there is an X-AspNet-Version header' do
        it 'identifies it as ASPX' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'X-AspNet-Version' => '4.0.30319' } }

            )
        end
    end

    context 'when there is an X-AspNetMvc-Version header' do
        it 'identifies it as ASPX' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'X-AspNetMvc-Version' => '2.0' } }

            )
        end
    end

end
