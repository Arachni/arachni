require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Apache do
    include_examples 'fingerprinter'

    def platforms
        [:apache]
    end

    context 'when there is an Server header' do
        it 'identifies it as Apache' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'Server' => 'Apache/2.2.21' } }
            )
        end
    end

    context 'when there is a X-Powered-By header' do
        it 'identifies it as Apache' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'X-Powered-By' => 'Stuf/0.4 (Apache)' } }
            )
        end
    end

    context 'when there is an Server header that includes Coyote' do
        it 'does not identify it as Apache' do
            expect(platforms_for( Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers:  { 'Server' => 'Apache-Coyote/1.1' } }
            )).to_a).to be_empty
        end
    end

end
