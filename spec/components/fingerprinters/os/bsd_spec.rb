require 'spec_helper'

describe Arachni::Platform::Fingerprinters::BSD do
    include_examples 'fingerprinter'

    def platforms
        [:bsd]
    end

    context 'when there is an Server header' do
        it 'identifies it as BSD' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'Server' => 'Apache/2.2.21 (FreeBSD)' } }
            )
        end
    end

    context 'when there is a X-Powered-By header' do
        it 'identifies it as BSD' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'X-Powered-By' => 'Stuf/0.4 (FreeBSD)' } }
            )
        end
    end

end
