require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Unix do
    include_examples 'fingerprinter'

    def platforms
        [:unix]
    end

    context 'when there is an Server header' do
        it 'identifies it as Unix' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'Server' => 'Apache/2.2.21 (Unix)' } }
            )
        end
    end

    context 'when there is a X-Powered-By header' do
        it 'identifies it as Unix' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'X-Powered-By' => 'Stuf/0.4 (Unix)' } }
            )
        end
    end

end
