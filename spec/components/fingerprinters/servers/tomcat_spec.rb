require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Tomcat do
    include_examples 'fingerprinter'

    def platforms
        [:tomcat, :java]
    end

    context 'when there is an Server header' do
        it 'identifies it as Tomcat' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'Server' => 'Tomcat/2.2.21' } }
            )
        end
    end

    context 'when there is a X-Powered-By header' do
        it 'identifies it as Tomcat' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers: { 'X-Powered-By' => 'Stuf/0.4 (Tomcat)' } }
            )
        end
    end

    context 'when there is an Server header' do
        it 'identifies it as Tomcat' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers:  { 'Server' => 'Apache-Coyote/1.1' } }
            )
        end
    end

end
