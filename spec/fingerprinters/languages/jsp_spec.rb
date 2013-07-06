require 'spec_helper'

describe Arachni::Platform::Fingerprinters::JSP do
    include_examples 'fingerprinter'

    context 'when the page has a .jsp extension' do
        it 'identifies it as JSP' do
            page = Arachni::Page.new( url: 'http://stuff.com/blah.jsp' )
            platforms_for( page ).should include :jsp
        end
    end

    context 'when there is a JSESSIONID query parameter' do
        it 'identifies it as JSP' do
            page = Arachni::Page.new(
                url:        'http://stuff.com/blah?JSESSIONID=stuff',
                query_vars: {
                    'JSESSIONID' => 'stuff'
                }
            )
            platforms_for( page ).should include :jsp
        end
    end

    context 'when there is a JSESSIONID cookie' do
        it 'identifies it as JSP' do
            page = Arachni::Page.new(
                url:     'http://stuff.com/blah',
                cookies: [Arachni::Cookie.new( 'http://stuff.com/blah',
                                               'JSESSIONID' => 'stuff' )]

            )
            platforms_for( page ).should include :jsp
        end
    end

    context 'when there is an X-Powered-By header with Servlet' do
        it 'identifies it as JSP' do
            page = Arachni::Page.new(
                url:     'http://stuff.com/blah',
                response_headers:  { 'X-Powered-By' => 'Servlet/2.4' }

            )
            platforms_for( page ).should include :jsp
        end
    end

    context 'when there is an X-Powered-By header with JSP' do
        it 'identifies it as JSP' do
            page = Arachni::Page.new(
                url:     'http://stuff.com/blah',
                response_headers:  { 'X-Powered-By' => 'JSP/2.1' }

            )
            platforms_for( page ).should include :jsp
        end
    end
end
