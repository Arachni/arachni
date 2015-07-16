require 'spec_helper'

describe Arachni::Platform::Fingerprinters::IIS do
    include_examples 'fingerprinter'

    def platforms
        [:iis, :windows]
    end

    context 'when there is an Server header' do
        it 'identifies it as IIS' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'Server' => 'IIS/2.2.21' } }
            )
        end
    end

    context 'when there is a X-Powered-By header' do
        it 'identifies it as IIS' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'X-Powered-By' => 'Stuf/0.4 (IIS)' } }
            )
        end
    end

end
