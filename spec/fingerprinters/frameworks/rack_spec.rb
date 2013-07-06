require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Rack do
    include_examples 'fingerprinter'

    context 'when there is a rack.session cookie' do
        it 'identifies it as Rack' do
            page = Arachni::Page.new(
                url:     'http://stuff.com/blah',
                cookies: [Arachni::Cookie.new( 'http://stuff.com/blah',
                                               'rack.session' => 'stuff' )]

            )
            platforms_for( page ).should include :ruby
            platforms_for( page ).should include :rack
        end
    end

    context 'when there is a Server header' do
        it 'identifies it as Rack' do
            page = Arachni::Page.new(
                url: 'http://stuff.com/blah',
                response_headers: { 'Server' => 'mod_rack' }
            )
            platforms_for( page ).should include :ruby
            platforms_for( page ).should include :rack
        end
    end

    context 'when there is an X-Powered-By header' do
        it 'identifies it as Rack' do
            page = Arachni::Page.new(
                url: 'http://stuff.com/blah',
                response_headers: { 'X-Powered-By' => 'mod_rack' }
            )
            platforms_for( page ).should include :ruby
            platforms_for( page ).should include :rack
        end
    end

end
