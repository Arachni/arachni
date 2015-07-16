require 'spec_helper'

describe Arachni::Platform::Fingerprinters::CherryPy do
    include_examples 'fingerprinter'

    def platforms
        [:python, :cherrypy]
    end

    context 'when there is a Server header' do
        it 'identifies it as CherryPy' do
            check_platforms Arachni::Page.from_data(
                url: 'http://stuff.com/blah',
                response: { headers: { 'Server' => 'CherryPy/0.1' } }
            )
        end
    end

    context 'when there is an X-Powered-By header' do
        it 'identifies it as CherryPy' do
            check_platforms Arachni::Page.from_data(
                url: 'http://stuff.com/blah',
                response: { headers: { 'X-Powered-By' => 'CherryPy/0.1' } }
            )
        end
    end

end
