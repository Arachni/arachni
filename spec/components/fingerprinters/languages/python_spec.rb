require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Python do
    include_examples 'fingerprinter'

    def platforms
        [:python]
    end

    context 'when the page has a .py extension' do
        it 'identifies it as Python' do
            check_platforms Arachni::Page.from_data( url: 'http://stuff.com/blah.py' )
        end
    end

    context 'when there is an X-Powered-By header' do
        it 'identifies it as Python' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'X-Powered-By' => 'Python/stuff' } }
            )
        end
    end

end
