require 'spec_helper'

class TrainerMockFramework
    attr_reader :pages
    attr_reader :opts
    attr_reader :trainer

    attr_accessor :sitemap

    def initialize( page = nil )
        @page        = page
        @pages       = []
        @on_audit_page = []

        Arachni::HTTP.reset
        @trainer = Arachni::Trainer.new( self )

        @opts = Arachni::Options.instance
        @opts.url = page.url if page

        @sitemap = []
    end

    def link_count_limit_reached?
        @opts.link_count_limit_reached? @sitemap.size
    end

    def run
        @on_audit_page.each do |b|
            b.call @page
        end

        Arachni::HTTP.run
    end

    def on_audit_page( &block )
        @on_audit_page << block
    end

    def push_to_page_queue( page )
        @sitemap << page.url
        @pages << page
    end
end

def request( url )
    Arachni::HTTP.instance.get( url.to_s, async: false ).response
end

describe Arachni::Trainer do

    before( :all ) do
        @url = web_server_url_for( :trainer )
        Arachni::Options.audit :links, :forms, :cookies, :headers
    end

    before( :each ) do
        Arachni::Options.reset

        res  = Arachni::HTTP.get( @url, async: false ).response
        @page = Arachni::Page.from_response( res, Arachni::Options.instance )

        @framework = TrainerMockFramework.new( @page )
        @trainer   = @framework.trainer
    end

    context 'when Options.fingerprint? is' do
        context true do
            it 'fingerprints the page' do
                Arachni::Options.no_fingerprinting = false
                Arachni::Options.fingerprint?.should be_true

                @framework.pages.should be_empty

                Arachni::HTTP.request( @url + '/fingerprint', train: true )
                @framework.run

                @framework.pages.size.should == 1
                @framework.pages.first.platforms.to_a.should == [:php]
            end
        end

        context false do
            it 'does not fingerprint the page' do
                Arachni::Options.no_fingerprinting = true
                Arachni::Options.fingerprint?.should be_false

                @framework.pages.should be_empty

                Arachni::HTTP.request( @url + '/fingerprint', train: true )
                @framework.run

                @framework.pages.should be_empty
            end
        end
    end

    describe 'HTTP requests with "train" set to' do
        describe 'nil' do
            it 'skips the Trainer' do
                @framework.pages.size.should == 0

                Arachni::HTTP.request( @url + '/elems' )
                @framework.run

                @framework.pages.size.should == 0
            end
        end
        describe false do
            it 'skips the Trainer' do
                @framework.pages.size.should == 0

                Arachni::HTTP.request( @url + '/elems', train: false )
                @framework.run

                @framework.pages.size.should == 0
            end
        end
        describe true do
            it 'passes the response to the Trainer' do
                @framework.pages.size.should == 0

                Arachni::HTTP.request( @url + '/elems', train: true )
                @framework.run

                @framework.pages.size.should == 1
            end

            context 'when a redirection leads to new elements' do
                it 'passes the response to the Trainer' do
                    @framework.pages.size.should == 0

                    Arachni::HTTP.request( @url + '/train/redirect', train: true )
                    @framework.run

                    page = @framework.pages.first
                    page.links.first.auditable.include?( 'msg' ).should be_true
                end
            end
        end
    end

    context 'when a page' do
        context 'has not changed' do
            it 'is skipped' do
                @framework.pages.size.should == 0

                Arachni::HTTP.request( @url, train: true )
                @framework.run

                @framework.pages.should be_empty
            end
        end

        context 'gets updated more than Trainer::MAX_TRAININGS_PER_URL times' do
            it 'is ignored' do
                get_response = proc do
                    Typhoeus::Response.new(
                        effective_url: @url,
                        body:          "<a href='?#{rand( 9999 )}=1'>Test</a>",
                        headers_hash: { 'Content-type' => 'text/html' },
                        request:      Typhoeus::Request.new( @url )
                    )
                end

                @trainer.page = Arachni::Page.from_response( get_response.call )

                pages = []
                @trainer.on_new_page { |p| pages << p }

                100.times { @trainer.push( get_response.call ) }

                pages.size.should == Arachni::Trainer::MAX_TRAININGS_PER_URL
            end
        end

        context 'matches excluding criteria' do
            it 'is ignored' do
                res = Typhoeus::Response.new(
                    effective_url: @url + '/exclude_me'
                )
                @trainer.push( res ).should be_false
            end
        end

        context 'matches a redundancy filter' do
            it 'should not be analyzed more than the specified amount of times' do
                Arachni::Options.url = 'http://stuff.com'
                trainer = TrainerMockFramework.new.trainer

                get_response = proc do
                    Typhoeus::Response.new(
                        effective_url: 'http://stuff.com/match_this',
                        body:          "<a href='?#{rand( 9999 )}=1'>Test</a>",
                        headers_hash: { 'Content-type' => 'text/html' },
                        request:      Typhoeus::Request.new( 'http://stuff.com/match_this' )
                    )
                end

                trainer.page = Arachni::Page.from_response( get_response.call )

                pages = []
                trainer.on_new_page { |p| pages << p }

                Arachni::Options.redundant = { /match_this/ => 10 }

                100.times { trainer.push( get_response.call ) }

                pages.size.should == 10
            end
        end
    end

    context 'when the link-count-limit is exceeded, following pages' do
        it 'is ignored' do
            Arachni::Options.url = 'http://stuff.com'

            framework = TrainerMockFramework.new
            trainer = framework.trainer

            get_response = proc do
                Typhoeus::Response.new(
                    effective_url: "http://stuff.com/#{rand( 9999 )}",
                    body:          "<a href='?#{rand( 9999 )}=1'>Test</a>",
                    headers_hash: { 'Content-type' => 'text/html' },
                    request:      Typhoeus::Request.new( 'http://stuff.com/match_this' )
                )
            end

            trainer.page = Arachni::Page.from_response( get_response.call )

            pages = []
            trainer.on_new_page { |p| pages << p }

            Arachni::Options.link_count_limit = 10
            100.times { trainer.push( get_response.call ) }

            pages.size.should == 10
        end
    end

    context 'when the content-type is' do
        context 'text-based' do
            it 'returns true' do
                @trainer.page = @page
                @trainer.push( request( @url ) ).should be_true
            end
        end

        context 'not text-based' do
            it 'returns false' do
                ct = @url + '/non_text_content_type'
                @trainer.push( request( ct ) ).should be_false
            end
        end
    end

    context 'when the response contains a new' do
        context 'form' do
            it 'returns a page with the new form' do
                url = @url + '/new_form'
                @trainer.page = @page
                @trainer.push( request( url ) ).should be_true
                page = @framework.pages.first
                page.should be_true
                page.forms.size.should == 1
                page.forms.first.auditable.include?( 'input2' ).should be_true
            end
        end

        context 'link' do
            it 'returns a page with the new link' do
                url = @url + '/new_link'
                @trainer.page = @page
                @trainer.push( request( url ) ).should be_true
                page = @framework.pages.first
                page.should be_true
                page.links.select { |l| l.auditable.include?( 'link_param' ) }.should be_any
            end
        end

        context 'cookie' do
            it 'returns a page with the new cookie appended' do
                url = @url + '/new_cookie'
                @trainer.page = @page
                @trainer.push( request( url ) ).should be_true
                page = @framework.pages.first
                page.should be_true
                page.cookies.last.auditable.include?( 'new_cookie' ).should be_true
            end
        end
    end

    context 'when the response is the result of a redirection' do
        it 'extracts query vars from the effective url' do
            url = @url + '/redirect?redirected=true'
            @trainer.page = @page
            @trainer.push( request( url ) ).should be_true
            page = @framework.pages.first
            page.links.last.auditable['redirected'].should == 'true'
        end
    end

end
