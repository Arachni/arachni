require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Tomcat do
    include_examples 'fingerprinter'

    context 'when there is an Server header' do
        it 'identifies it as Tomcat' do
            page = Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'Server' => 'Tomcat/2.2.21' } }
            )
            platforms_for( page ).should include :tomcat
            platforms_for( page ).should include :jsp
        end
    end

    context 'when there is a X-Powered-By header' do
        it 'identifies it as Tomcat' do
            page = Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'X-Powered-By' => 'Stuf/0.4 (Tomcat)' } }
            )
            platforms_for( page ).should include :tomcat
            platforms_for( page ).should include :jsp
        end
    end

end
