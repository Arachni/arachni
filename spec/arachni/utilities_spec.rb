# encoding: utf-8
require 'spec_helper'

class Subject
    include Arachni::UI::Output
    include Arachni::Utilities
end

describe Arachni::Utilities do

    before( :each ) do
        @opts = Arachni::Options.reset
    end

    subject { Subject.new }

    describe '#caller_name' do
        it 'returns the filename of the caller' do
            subject.caller_name.should == 'example'
        end
    end

    describe '#caller_path' do
        it 'returns the filepath of the caller' do
            subject.caller_path.should == Kernel.caller.first.match( /^(.+):\d/ )[1]
        end
    end

    {
        forms_from_response:     [Arachni::Element::Form, :from_response],
        forms_from_document:     [Arachni::Element::Form, :from_document],
        form_encode:             [Arachni::Element::Form, :encode],
        form_decode:             [Arachni::Element::Form, :decode],
        form_parse_request_body: [Arachni::Element::Form, :parse_request_body],
        links_from_response:     [Arachni::Element::Link, :from_response],
        links_from_document:     [Arachni::Element::Link, :from_document],
        cookies_from_response:   [Arachni::Element::Cookie, :from_response],
        cookies_from_document:   [Arachni::Element::Cookie, :from_document],
        cookies_from_file:       [Arachni::Element::Cookie, :from_file],
        cookie_encode:           [Arachni::Element::Cookie, :encode],
        cookie_decode:           [Arachni::Element::Cookie, :decode],
        parse_set_cookie:        [Arachni::Element::Cookie, :parse_set_cookie],
        page_from_response:      [Arachni::Page, :from_response],
        page_from_url:           [Arachni::Page, :from_url],
        html_decode:             [CGI, :unescapeHTML],
        html_unescape:           [CGI, :unescapeHTML],
        html_encode:             [CGI, :escapeHTML],
        html_escape:             [CGI, :escapeHTML],
        uri_parse:               [Arachni::URI, :parse],
        uri_rewrite:             [Arachni::URI, :rewrite],
        uri_parse_query:         [Arachni::URI, :parse_query],
        uri_encode:              [Arachni::URI, :encode],
        uri_decode:              [Arachni::URI, :decode],
        normalize_url:           [Arachni::URI, :normalize],
        to_absolute:             [Arachni::URI, :to_absolute]
    }.each do |m, (klass, delegated)|
        describe "##{m}" do
            it "delegates to #{klass}.#{delegated}" do
                ret = :blah

                klass.stub(delegated){ ret }
                subject.send( m, 'stuff' ).should == ret
            end
        end
    end

    describe '#uri_parser' do
        it 'returns a URI::Parser' do
            subject.uri_parser.class.should == ::URI::Parser
        end
    end

    {
        get_path: :up_to_path,
    }.each do |k, v|
        describe "##{k}" do
            it "delegates to #{Arachni::URI}##{v}" do
                Arachni::URI.any_instance.stub(v) { :stuff }
                subject.send( k, 'http://url/' ).should == :stuff
            end
        end
    end

    {
        :redundant_path?  => :redundant?,
        :path_in_domain?  => :in_domain?,
        :path_too_deep?   => :too_deep?,
        :exclude_path?    => :exclude?,
        :include_path?    => :include?,
        :follow_protocol? => :follow_protocol?,
    }.each do |k, v|
        describe "##{k}" do
            it "delegates to #{Arachni::URI::Scope}##{v}" do
                Arachni::URI::Scope.any_instance.stub(v) { :stuff }
                subject.send( k, 'http://url/' ).should == :stuff
            end
        end
    end

    describe '#port_available?' do
        context 'when a port is available' do
            it 'returns true' do
                subject.port_available?( 7777 ).should be_true
            end
        end

        context 'when a port is not available' do
            it 'returns true' do
                s = TCPServer.new( 7777 )
                subject.port_available?( 7777 ).should be_false
                s.close
            end
        end
    end

    describe '#skip_page?' do
        before { @opts.scope.exclude_page_patterns << /ignore me/ }

        context 'when the page DOM depth limit has been exceeded' do
            it 'returns false' do
                page = Arachni::Page.from_data(
                    url:         'http://test',
                    dom:         {
                        transitions: [
                             { page: :load },
                             { "<a href='javascript:click();'>" => :click },
                             { "<button dblclick='javascript:doubleClick();'>" => :ondblclick }
                         ].map { |t| Arachni::Page::DOM::Transition.new *t.first }
                    }
                )
                subject.skip_page?( page ).should be_false

                @opts.scope.dom_depth_limit = 2
                subject.skip_page?( page ).should be_true
            end
        end

        context 'when the body matches an ignore rule' do
            it 'returns true' do
                page = Arachni::Page.from_data( url: 'http://test/', body: 'ignore me' )
                subject.skip_page?( page ).should be_true
            end
        end

        context 'when the body does not match an ignore rule' do
            it 'returns false' do
                page = Arachni::Page.from_data(
                    url: 'http://test/',
                    body: 'not me'
                )
                subject.skip_page?( page ).should be_false
            end
        end
    end

    describe '#skip_response?' do
        before { @opts.scope.exclude_page_patterns << /ignore me/ }

        context 'when the body matches an ignore rule' do
            it 'returns true' do
                res = Arachni::HTTP::Response.new( url: 'http://stuff/', body: 'ignore me' )
                subject.skip_response?( res ).should be_true
            end
        end

        context 'when the body does not match an ignore rule' do
            it 'returns false' do
                res = Arachni::HTTP::Response.new(
                    url: 'http://test/',
                    body: 'not me'
                )
                subject.skip_response?( res ).should be_false
            end
        end
    end

    describe '#skip_resource?' do
        before do
            @opts.scope.exclude_page_patterns << /ignore\s+me/m
            @opts.scope.exclude_path_patterns << /ignore/
        end

        context 'when passed a' do
            context Arachni::HTTP::Response do

                context 'whose body matches an ignore rule' do
                    it 'returns true' do
                        res = Arachni::HTTP::Response.new(
                            url: 'http://stuff/here',
                            body: 'ignore me'
                        )
                        subject.skip_resource?( res ).should be_true
                    end
                end

                context 'whose the body does not match an ignore rule' do
                    it 'returns false' do
                        res = Arachni::HTTP::Response.new(
                            url: 'http://stuff/here',
                            body: 'stuff'
                        )
                        subject.skip_resource?( res ).should be_false
                    end
                end

                context 'whose URL matches an exclude rule' do
                    it 'returns true' do
                        res = Arachni::HTTP::Response.new(
                            url: 'http://stuff/here/to/ignore/',
                            body: 'ignore me'
                        )
                        subject.skip_resource?( res ).should be_true
                    end
                end

                context 'whose URL does not match an exclude rule' do
                    it 'returns false' do
                        res = Arachni::HTTP::Response.new(
                            url: 'http://stuff/here',
                            body: 'stuff'
                        )
                        subject.skip_resource?( res ).should be_false
                    end
                end
            end

            context Arachni::Page do
                context 'whose the body matches an ignore rule' do
                    it 'returns true' do
                        page = Arachni::Page.from_data(
                            url:   'http://stuff/here',
                            body: 'ignore me'
                        )
                        subject.skip_resource?( page ).should be_true
                    end
                end

                context 'whose the body does not match an ignore rule' do
                    it 'returns false' do
                        page = Arachni::Page.from_data(
                            url:   'http://stuff/here',
                            body: 'stuff'
                        )
                        subject.skip_resource?( page ).should be_false
                    end
                end

                context 'whose URL matches an exclude rule' do
                    it 'returns true' do
                        res = Arachni::Page.from_data(
                            url:   'http://stuff/here/to/ignore/',
                            body: 'ignore me'
                        )
                        subject.skip_resource?( res ).should be_true
                    end
                end

                context 'whose URL does not match an exclude rule' do
                    it 'returns false' do
                        res = Arachni::Page.from_data(
                            url:  'http://stuff/here',
                            body: 'stuff'
                        )
                        subject.skip_resource?( res ).should be_false
                    end
                end

            end

            context String do
                context 'with multiple lines' do
                    context 'which matches an ignore rule' do
                        it 'returns true' do
                            s = "ignore \n me"
                            subject.skip_resource?( s ).should be_true
                        end
                    end

                    context 'which does not match an ignore rule' do
                        it 'returns false' do
                            s = "multi \n line \n stuff here"
                            subject.skip_resource?( s ).should be_false
                        end
                    end
                end

                context 'with a single line' do
                    context 'which matches an exclude rule' do
                        it 'returns true' do
                            s = 'ignore/this/path'
                            subject.skip_resource?( s ).should be_true
                        end
                    end

                    context 'which does not match an exclude rule' do
                        it 'returns false' do
                            s = 'stuf/here/'
                            subject.skip_resource?( s ).should be_false
                        end
                    end

                end
            end
        end
    end

    describe '#seed' do
        it 'returns a random string' do
            subject.seed.class.should == String
        end
    end

    describe '#secs_to_hms' do
        it 'converts seconds to HOURS:MINUTES:SECONDS' do
            subject.secs_to_hms( 0 ).should == '00:00:00'
            subject.secs_to_hms( 1 ).should == '00:00:01'
            subject.secs_to_hms( 60 ).should == '00:01:00'
            subject.secs_to_hms( 60*60 ).should == '01:00:00'
            subject.secs_to_hms( 60*60 + 60 + 1 ).should == '01:01:01'
        end
    end

    describe '#exception_jail' do
        context 'when no error occurs' do
            it 'returns the return value of the block' do
                subject.exception_jail { :stuff }.should == :stuff
            end
        end

        context "when a #{RuntimeError} occurs" do
            context 'and raise_exception is' do
                context 'default' do
                    it 're-raises the exception' do
                        expect do
                            subject.exception_jail { raise }
                        end.to raise_error RuntimeError
                    end
                end

                context true do
                    it 're-raises the exception' do
                        expect do
                            subject.exception_jail( true ) { raise }
                        end.to raise_error RuntimeError
                    end
                end

                context false do
                    it 'returns nil' do
                        subject.exception_jail( false ) { raise }.should be_nil
                    end
                end
            end
        end

        context "when an #{Exception} occurs" do
            context 'and raise_exception is' do
                context 'default' do
                    it 'does not rescue it' do
                        expect do
                            subject.exception_jail { raise Exception }
                        end.to raise_error Exception
                    end
                end

                context true do
                    it 'does not rescue it' do
                        expect do
                            subject.exception_jail( true ) { raise Exception }
                        end.to raise_error Exception
                    end
                end

                context false do
                    it 'does not rescue it' do
                        expect do
                            subject.exception_jail( false ) { raise Exception }
                        end.to raise_error Exception
                    end
                end
            end
        end
    end

end
