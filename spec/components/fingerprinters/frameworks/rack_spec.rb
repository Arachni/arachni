require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Rack do
    include_examples 'fingerprinter'

    def platforms
        [:ruby, :rack]
    end

    context 'when there is a rack.session cookie' do
        it 'identifies it as Rack' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                cookies: [Arachni::Cookie.new(
                              url:    'http://stuff.com/blah',
                              inputs: { 'rack.session' => 'stuff' } )]

            )
        end
    end

    context 'when there is an X-Powered-By header' do
        it 'identifies it as Rack' do
            check_platforms Arachni::Page.from_data(
                url: 'http://stuff.com/blah',
                response: { headers: { 'X-Powered-By' => 'mod_rack' } }
            )
        end
    end

    context 'when there is an X-Rack-* header' do
        it 'identifies it as Rack' do
            check_platforms Arachni::Page.from_data(
                url: 'http://stuff.com/blah',
                response: { headers: { 'X-Rack-Stuff' => 'Blah' } }
            )
        end
    end
end
