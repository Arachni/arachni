require 'spec_helper'

class TrainerMockFramework
    attr_reader :pages
    attr_reader :opts
    attr_reader :trainer

    attr_accessor :sitemap

    def initialize( page = nil )
        @page        = page
        @pages       = []
        @on_page_audit = []

        http.reset
        @trainer = Arachni::Trainer.new( self )

        @opts = Arachni::Options.instance
        @opts.url = page.url if page

        @sitemap = []
    end

    def page_limit_reached?
        @opts.scope.page_limit_reached? @sitemap.size
    end

    def run
        @on_page_audit.each do |b|
            b.call @page
        end

        http.run
    end

    def http
        Arachni::HTTP::Client
    end

    def on_page_audit( &block )
        @on_page_audit << block
    end

    def push_to_page_queue( page )
        @sitemap << page.url
        @pages << page
    end
end

def request( url )
    Arachni::HTTP::Client.get( url.to_s, mode: :sync )
end

describe Arachni::Trainer do

    before( :all ) do
        @url = web_server_url_for( :trainer )
        Arachni::Options.audit.elements :links, :forms, :cookies, :headers
    end

    before( :each ) do
        Arachni::Options.reset

        @page = Arachni::Page.from_url( @url )

        @framework = TrainerMockFramework.new( @page )
        @trainer   = @framework.trainer
    end

    context 'when Options.fingerprint? is' do
        context true do
            it 'fingerprints the page' do
                Arachni::Options.no_fingerprinting = false
                Arachni::Options.fingerprint?.should be_true

                @framework.pages.should be_empty

                Arachni::HTTP::Client.request( @url + '/fingerprint', train: true )
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

                Arachni::HTTP::Client.request( @url + '/fingerprint', train: true )
                @framework.run

                @framework.pages.should be_empty
            end
        end
    end

    describe 'HTTP requests with "train" set to' do
        describe 'nil' do
            it 'skips the Trainer' do
                @framework.pages.size.should == 0

                Arachni::HTTP::Client.request( @url + '/elems' )
                @framework.run

                @framework.pages.size.should == 0
            end
        end
        describe false do
            it 'skips the Trainer' do
                @framework.pages.size.should == 0

                Arachni::HTTP::Client.request( @url + '/elems', train: false )
                @framework.run

                @framework.pages.size.should == 0
            end
        end
        describe true do
            it 'passes the response to the Trainer' do
                @framework.pages.size.should == 0

                Arachni::HTTP::Client.request( @url + '/elems', train: true )
                @framework.run

                @framework.pages.size.should == 1
            end

            context 'when a redirection leads to new elements' do
                it 'passes the response to the Trainer' do
                    @framework.pages.size.should == 0

                    Arachni::HTTP::Client.request( @url + '/train/redirect', train: true )
                    @framework.run

                    page = @framework.pages.first
                    page.links.first.inputs.include?( 'msg' ).should be_true
                end
            end
        end
    end

    context 'when a page' do
        context 'has not changed' do
            it 'is skipped' do
                @framework.pages.size.should == 0

                Arachni::HTTP::Client.request( @url, train: true )
                @framework.run

                @framework.pages.should be_empty
            end
        end

        context 'gets updated more than Trainer::MAX_TRAININGS_PER_URL times' do
            it 'is ignored' do
                get_response = proc do
                    Arachni::HTTP::Response.new(
                        url: @url,
                        body:    "<a href='?#{rand( 9999 )}=1'>Test</a>",
                        headers: { 'Content-type' => 'text/html' },
                        request: Arachni::HTTP::Request.new( url: @url )
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
                res = Arachni::HTTP::Response.new(
                    url: @url + '/exclude_me'
                )
                @trainer.push( res ).should be_false
            end
        end

        context 'matches a redundancy filter' do
            it 'should not be analyzed more than the specified amount of times' do
                Arachni::Options.url = 'http://stuff.com'
                trainer = TrainerMockFramework.new.trainer

                get_response = proc do
                    Arachni::HTTP::Response.new(
                        url: 'http://stuff.com/match_this',
                        body:          "<a href='?#{rand( 9999 )}=1'>Test</a>",
                        headers: { 'Content-type' => 'text/html' },
                        request:      Arachni::HTTP::Request.new( url: 'http://stuff.com/match_this' )
                    )
                end

                trainer.page = Arachni::Page.from_response( get_response.call )

                pages = []
                trainer.on_new_page { |p| pages << p }

                Arachni::Options.scope.redundant_path_patterns = { /match_this/ => 10 }

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
                Arachni::HTTP::Response.new(
                    url: "http://stuff.com/#{rand( 9999 )}",
                    body:          "<a href='?#{rand( 9999 )}=1'>Test</a>",
                    headers: { 'Content-type' => 'text/html' },
                    request:      Arachni::HTTP::Request.new( url: 'http://stuff.com/match_this' )
                )
            end

            trainer.page = Arachni::Page.from_response( get_response.call )

            pages = []
            trainer.on_new_page { |p| pages << p }

            Arachni::Options.scope.page_limit = 10
            100.times { trainer.push( get_response.call ) }

            pages.size.should == 10
        end
    end

    describe '#push' do
        context 'when an error occurs' do
            it 'returns nil' do
                @trainer.page = @page

                @trainer.stub(:analyze) { raise }

                @trainer.push( request( @url ) ).should be_nil
            end
        end

        context 'when the resource is out-of-scope' do
            it 'returns false' do
                @trainer.page = @page

                Arachni::Options.scope.exclude_path_patterns = @url
                @trainer.push( request( @url ) ).should be_false
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

                    pages = @framework.pages
                    pages.size.should == 1

                    page = pages.pop
                    new_forms = (page.forms - @page.forms)
                    new_forms.size.should == 1
                    new_forms.first.inputs.include?( 'input2' ).should be_true
                end
            end

            context 'link' do
                it 'returns a page with the new link' do
                    url = @url + '/new_link'
                    @trainer.page = @page
                    @trainer.push( request( url ) ).should be_true

                    page = @framework.pages.first

                    new_links = (page.links - @page.links)
                    new_links.size.should == 1
                    new_links.select { |l| l.inputs.include?( 'link_param' ) }.should be_any
                end
            end

            context 'cookie' do
                it 'returns a page with the new cookie appended' do
                    url = @url + '/new_cookie'
                    @trainer.page = @page
                    @trainer.push( request( url ) ).should be_true

                    page = @framework.pages.first
                    page.cookies.size.should == 2
                    page.cookies.select { |l| l.inputs.include?( 'new_cookie' ) }.should be_any
                end
            end
        end

        context 'when the response is the result of a redirection' do
            it 'extracts query vars from the effective url' do
                url = @url + '/redirect?redirected=true'
                @trainer.page = @page
                @trainer.push( request( url ) ).should be_true
                page = @framework.pages.first
                page.links.last.inputs['redirected'].should == 'true'
            end
        end
    end

end
