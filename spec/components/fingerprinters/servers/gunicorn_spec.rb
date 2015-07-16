require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Gunicorn do
    include_examples 'fingerprinter'

    def platforms
        [:python, :gunicorn]
    end

    context 'when there is a Server header' do
        it 'identifies it as Gunicorn' do
            check_platforms Arachni::Page.from_data(
                url: 'http://stuff.com/blah',
                response: { headers: { 'Server' => 'gunicorn/18.0' } }
            )
        end
    end

    context 'when there are X-Gunicorn headers' do
        it 'identifies it as Gunicorn' do
            check_platforms Arachni::Page.from_data(
                url: 'http://stuff.com/blah',
                response: { headers: { 'X-Gunicorn-Stuff' => 'Blah' } }
            )
        end
    end

end
