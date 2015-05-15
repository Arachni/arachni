require 'spec_helper'

describe Arachni::Platform::Fingerprinters::Java do
    include_examples 'fingerprinter'

    def platforms
        [:java]
    end

    context 'when the page has a .jsp extension' do
        it 'identifies it as JSP' do
            check_platforms Arachni::Page.from_data( url: 'http://stuff.com/blah.jsp' )
        end
    end

    context 'when there is a JSESSIONID query parameter' do
        it 'identifies it as Java' do
            check_platforms Arachni::Page.from_data(
                url: 'http://stuff.com/blah?JSESSIONID=stuff'
            )
        end
    end

    context 'when there is a JSESSIONID cookie' do
        it 'identifies it as Java' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                cookies: [Arachni::Cookie.new(
                              url: 'http://stuff.com/blah',
                              inputs: { 'JSESSIONID' => 'stuff' } )]
            )
        end
    end

    context 'when there is an X-Powered-By header with Servlet' do
        it 'identifies it as Java' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers:  { 'X-Powered-By' => 'Servlet/2.4' } }
            )
        end
    end

    context 'when there is an X-Powered-By header with JSP' do
        it 'identifies it as Java' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers:  { 'X-Powered-By' => 'JSP/2.1' } }
            )
        end
    end

    context 'when there is an X-Powered-By header with JBoss' do
        it 'identifies it as Java' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers:  { 'X-Powered-By' => 'JBossWeb-2.1' } }
            )
        end
    end

    context 'when there is an X-Powered-By header with GlassFish' do
        it 'identifies it as Java' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers:  { 'X-Powered-By' => 'GlassFish Server' } }
            )
        end
    end

    context 'when there is an X-Powered-By header with Java' do
        it 'identifies it as Java' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers:  { 'X-Powered-By' => 'Java' } }
            )
        end
    end

    context 'when there is an X-Powered-By header with Oracle' do
        it 'identifies it as Java' do
            check_platforms Arachni::Page.from_data(
                url:     'http://stuff.com/blah',
                response: { headers:  { 'X-Powered-By' => 'Oracle-Application-Server-10g/10.1.3.5.0 Oracle-HTTP-Server' } }
            )
        end
    end
end
