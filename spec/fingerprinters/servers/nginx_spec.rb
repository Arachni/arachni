require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Nginx do
    include_examples 'fingerprinter'

    context 'when there is an Server header' do
        it 'identifies it as Nginx' do
            page = Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'Server' => 'Nginx/2.2.21' } }
            )
            platforms_for( page ).should include :nginx
        end
    end

    context 'when there is a X-Powered-By header' do
        it 'identifies it as Nginx' do
            page = Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'X-Powered-By' => 'Stuf/0.4 (Nginx)' } }
            )
            platforms_for( page ).should include :nginx
        end
    end

end
