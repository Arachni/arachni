require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Nette do
    include_examples 'fingerprinter'

    def platforms
        [:php, :nette]
    end

    context 'when there is a Server header' do
        it 'identifies it as Nette' do
            check_platforms Arachni::Page.from_data(
                url: 'http://stuff.com/blah',
                response: { headers: { 'Server' => 'Nette/0.1' } }
            )
        end
    end

    context 'when there is an X-Powered-By header' do
        it 'identifies it as Nette' do
            check_platforms Arachni::Page.from_data(
                url: 'http://stuff.com/blah',
                response: { headers: { 'X-Powered-By' => 'Nette/0.1' } }
            )
        end
    end

    context 'when there is a nette-browser cookie' do
        it 'identifies it as Nette' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                cookies: [Arachni::Cookie.new(
                              url:    'http://stuff.com/blah',
                              inputs: { 'nette-browser' => 'stuff' } )]

            )
        end
    end

end
