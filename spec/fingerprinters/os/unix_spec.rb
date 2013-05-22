require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Unix do
    include_examples 'fingerprinter'

    context 'when there is an Server header' do
        it 'identifies it as Unix' do
            page = Arachni::Page.new(
                url:     'http://stuff.com/blah',
                response_headers: { 'Server' => 'Apache/2.2.21 (Unix)' }
            )
            platforms_for( page ).should include :unix
        end
    end

    context 'when there is a X-Powered-By header' do
        it 'identifies it as Unix' do
            page = Arachni::Page.new(
                url:     'http://stuff.com/blah',
                response_headers: { 'X-Powered-By' => 'Stuf/0.4 (Unix)' }
            )
            platforms_for( page ).should include :unix
        end
    end

end
