require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Rails do
    include_examples 'fingerprinter'

    def platforms
        [:ruby, :rack, :rails]
    end

    context 'when there is an Server header' do
        context 'and it contains Rails' do
            it 'identifies it as Ruby' do
                check_platforms Arachni::Page.from_data(
                    url:     'http://stuff.com/blah',
                    response: { headers: { 'Server' => 'Rails' } }
                )
            end
        end
    end

    context 'when there is a X-Powered-By header' do
        context 'and it contains X-Powered-By' do
            it 'identifies it as Rails' do
                check_platforms Arachni::Page.from_data(
                    url:     'http://stuff.com/blah',
                    response: { headers: { 'X-Powered-By' => 'Rails' } }
                )
            end
        end
    end

    context 'when there are X-Rails headers' do
        it 'identifies it as Rails' do
            check_platforms Arachni::Page.from_data(
                url: 'http://stuff.com/blah',
                response: { headers: { 'X-Rails-Stuff' => 'Blah' } }
            )
        end
    end

    context 'when there is a _rails_admin_session cookie' do
        it 'identifies it as Rails' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                cookies: [Arachni::Cookie.new(
                              url:    'http://stuff.com/blah',
                              inputs: { '_rails_admin_session' => 'stuff' } )]

            )
        end
    end

end
