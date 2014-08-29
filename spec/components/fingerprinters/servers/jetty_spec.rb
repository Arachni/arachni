require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Jetty do
    include_examples 'fingerprinter'

    context 'when there is an Server header' do
        it 'identifies it as Jetty' do
            page = Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'Server' => 'Jetty/2.2.21' } }
            )
            platforms_for( page ).should include :jetty
            platforms_for( page ).should include :jsp
        end
    end

    context 'when there is a X-Powered-By header' do
        it 'identifies it as Jetty' do
            page = Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'X-Powered-By' => 'Stuff/0.4 (Jetty)' } }
            )
            platforms_for( page ).should include :jetty
            platforms_for( page ).should include :jsp
        end
    end

end
