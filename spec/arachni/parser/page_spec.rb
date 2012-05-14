require_relative '../../spec_helper'

describe Arachni::Parser::Page do
    before( :all ) do
        @page_data = {
            url: 'http://a-url.com',
            code: 200,
            method: 'get',
            query_vars: {
                'myvar' => 'my value'
            },
            html: 'some html code',
            response_headers: {
                'header-name' => 'header value'
            },
            paths: [
                'http://a-url.com/path',
                'http://a-url.com/a/path',
                'http://a-url.com/another/path/'
            ],
            links: [],
            forms: [],
            cookies: [],
            headers: [],
            cookiejar: {
                'cookiename' => 'cokie value'
            }
        }

        @opts = Arachni::Options.instance
        @opts.audit_links = true
        @opts.audit_forms = true
        @opts.audit_cookies = true
        @opts.audit_headers = true

        @page = Arachni::Parser::Page.new( @page_data )
        @empty_page = Arachni::Parser::Page.new
    end

    context 'when called with options' do
        it 'should retain its options' do
            @page_data.each {
                |k, v|
                @page.instance_variable_get( "@#{k}".to_sym ).should == v
            }
        end
    end

    context 'when called without options' do
        describe '#links' do
            it 'should default to empty array' do
                @empty_page.links.should == []
            end
        end

        describe '#forms' do
            it 'should default to empty array' do
                @empty_page.forms.should == []
            end
        end

        describe '#cookies' do
            it 'should default to empty array' do
                @empty_page.cookies.should == []
            end
        end

        describe '#headers' do
            it 'should default to empty array' do
                @empty_page.headers.should == []
            end
        end

        describe '#cookiejar' do
            it 'should default to empty hash' do
                @empty_page.cookiejar.should == {}
            end
        end

        describe '#paths' do
            it 'should default to empty array' do
                @empty_page.paths.should == []
            end
        end

        describe '#response_headers' do
            it 'should default to empty array' do
                @empty_page.paths.should == []
            end
        end

        describe '#query_vars' do
            it 'should default to empty hash' do
                @empty_page.query_vars.should == {}
            end
        end

        describe '#html' do
            it 'should default to empty hash' do
                @empty_page.html.should == ''
            end
        end

        describe '#body' do
            it 'should default to empty string' do
                @empty_page.body.should == ''
            end
        end
    end

    describe '.from_http_response' do
        it 'should return a page from an HTTP response and opts' do
            res = Typhoeus::Response.new( effective_url: 'http://url.com' )
            page = Arachni::Parser::Page.from_http_response( res, Arachni::Options.instance )
            page.class.should == Arachni::Parser::Page
        end
    end

end
