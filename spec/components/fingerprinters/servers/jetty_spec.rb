require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Jetty do
    include_examples 'fingerprinter'

    def platforms
        [:jetty, :java]
    end

    context 'when there is an Server header' do
        it 'identifies it as Jetty' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'Server' => 'Jetty/2.2.21' } }
            )
        end
    end

    context 'when there is a X-Powered-By header' do
        it 'identifies it as Jetty' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'X-Powered-By' => 'Stuff/0.4 (Jetty)' } }
            )
        end
    end

end
