require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Django do
    include_examples 'fingerprinter'

    def platforms
        [:python, :django]
    end

    context 'when there is a Server header' do
        it 'identifies it as Django' do
            check_platforms Arachni::Page.from_data(
                url: 'http://stuff.com/blah',
                response: { headers: { 'Server' => 'WSGIServer/0.1mt Django/2.7.4' } }
            )
        end
    end

    context 'when there is an X-Powered-By header' do
        it 'identifies it as Django' do
            check_platforms Arachni::Page.from_data(
                url: 'http://stuff.com/blah',
                response: { headers: { 'X-Powered-By' => 'Django' } }
            )
        end
    end

    context 'when there are X-Django headers' do
        it 'identifies it as Django' do
            check_platforms Arachni::Page.from_data(
                url: 'http://stuff.com/blah',
                response: { headers: { 'X-Django-Stuff' => 'Blah' } }
            )
        end
    end

end
