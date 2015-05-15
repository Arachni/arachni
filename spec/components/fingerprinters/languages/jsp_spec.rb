require 'spec_helper'

describe Arachni::Platform::Fingerprinters::JSP do
    include_examples 'fingerprinter'

    def platforms
        [:jsp]
    end

    context 'when the page has a .jsp extension' do
        it 'identifies it as JSP' do
            check_platforms Arachni::Page.from_data( url: 'http://stuff.com/blah.jsp' )
        end
    end

    context 'when there is a JSESSIONID query parameter' do
        it 'identifies it as JSP' do
            page = check_platforms Arachni::Page.from_data(
                url: 'http://stuff.com/blah?JSESSIONID=stuff'
            )
        end
    end

    context 'when there is a JSESSIONID cookie' do
        it 'identifies it as JSP' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                cookies: [Arachni::Cookie.new(
                              url: 'http://stuff.com/blah',
                              inputs: { 'JSESSIONID' => 'stuff' } )]

            )
        end
    end

    context 'when there is an X-Powered-By header with Servlet' do
        it 'identifies it as JSP' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers:  { 'X-Powered-By' => 'Servlet/2.4' } }

            )
        end
    end

    context 'when there is an X-Powered-By header with JSP' do
        it 'identifies it as JSP' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers:  { 'X-Powered-By' => 'JSP/2.1' } }

            )
        end
    end
end
