require 'spec_helper'

describe Arachni::Platform::Fingerprinters::JSF do
    include_examples 'fingerprinter'

    def platforms
        [:java, :jsf]
    end

    context 'when there is an X-Powered-By header with JSF' do
        it 'identifies it as JSF' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers:  { 'X-Powered-By' => 'JSF/2.1' } }
            )
        end
    end

    context 'when there is a javax.faces.Token query parameter' do
        it 'identifies it as JSF' do
            check_platforms Arachni::Page.from_data(
                url: 'http://stuff.com/blah?javax.faces.Token=stuff'
            )
        end
    end

end
