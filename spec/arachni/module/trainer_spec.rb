require_relative '../../spec_helper'

describe Arachni::Module::Trainer do

    def request( url )
        http_opts = {
            async: false,
            remove_id: true
        }
        Arachni::HTTP.instance.get( url.to_s, http_opts ).response
    end

    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.url = @base_url = server_url_for( :trainer )
        @opts.exclude << Regexp.new( 'exclude_me' )
        @opts.audit_links = true
        @opts.audit_forms = true
        @opts.audit_cookies = true

        @page = Arachni::Parser::Page.from_http_response( request( @opts.url ), @opts )

        @trainer = Arachni::Module::Trainer.new( @opts )
        @trainer.init_from_page!( @page )
    end

    describe '#add_response' do

        context 'when the page has not changed' do
            it 'should not analyze it' do
                url = @base_url
                @trainer.add_response( request( url ) ).should be_true
                @trainer.flush_pages.should be_empty
            end
        end

        context 'when the content-type is' do
            context 'text-based' do
                it 'should return true' do
                    @trainer.add_response( request( @base_url ) ).should be_true
                end
            end

            context 'not text-based' do
                it 'should return false' do
                    ct = @base_url + '/non_text_content_type'
                    @trainer.add_response( request( ct ) ).should be_false
                end
            end
        end

        context 'when the URL matches excluding criteria' do
            it 'should return false' do
                res = Typhoeus::Response.new(
                    effective_url: @base_url + '/exclude_me'
                )
                @trainer.add_response( res ).should be_false
            end
        end

        context 'when the response contains a new form' do
            it 'should return a page with the new form' do
                url = @base_url + '/new_form'
                @trainer.add_response( request( url ) ).should be_true
                page = @trainer.flush_pages.first
                page.should be_true
                page.forms.size.should == 1
                page.forms.first.auditable.include?( 'input2' ).should be_true
            end
        end

        context 'when the response contains a new link' do
            it 'should return a page with the new link' do
                url = @base_url + '/new_link'
                @trainer.add_response( request( url ) ).should be_true
                page = @trainer.flush_pages.first
                page.should be_true
                page.links.size.should == 1
                page.links.first.auditable.include?( 'link_param' ).should be_true
            end
        end

        context 'when the response contains a new cookie' do
            it 'should return a page with the new cookie appended' do
                url = @base_url + '/new_cookie'
                @trainer.add_response( request( url ) ).should be_true
                page = @trainer.flush_pages.first
                page.should be_true
                page.cookies.last.auditable.include?( 'new_cookie' ).should be_true
            end
        end

        context 'when the response is the result of a redirection' do
            it 'should extract query vars from the effective url' do
                url = @base_url + '/redirect?redirected=true'
                @trainer.add_response( request( url ), true ).should be_true
                page = @trainer.flush_pages.first
                page.links.last.auditable['redirected'].should == 'true'
            end
        end

    end
end
