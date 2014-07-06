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

    let(:response) { Factory[:response] }
    let(:page) { Factory[:page] }

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
        request_parse_body:      [Arachni::HTTP::Request, :parse_body],
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
        it "delegates to #{Arachni::Page::Scope}#out?" do
            Arachni::Page::Scope.any_instance.stub(:out?) { :stuff }
            subject.skip_page?( page ).should == :stuff
        end
    end

    describe '#skip_response?' do
        it "delegates to #{Arachni::HTTP::Response::Scope}#out?" do
            Arachni::HTTP::Response::Scope.any_instance.stub(:out?) { :stuff }
            subject.skip_response?( response ).should == :stuff
        end
    end

    describe '#skip_resource?' do
        context 'when passed a' do
            context Arachni::HTTP::Response do
                context 'and #skip_response? returns' do
                    context 'true' do
                        it 'returns true' do
                            subject.stub(:skip_response?){ true }
                            subject.skip_resource?( response ).should be_true
                        end
                    end

                    context 'false' do
                        it 'returns false' do
                            subject.stub(:skip_response?){ false }
                            subject.skip_resource?( response ).should be_false
                        end
                    end
                end
            end

            context Arachni::Page do
                context 'and #skip_page? returns' do
                    context 'true' do
                        it 'returns true' do
                            subject.stub(:skip_page?){ true }
                            subject.skip_resource?( page ).should be_true
                        end
                    end

                    context 'false' do
                        it 'returns false' do
                            subject.stub(:skip_page?){ false }
                            subject.skip_resource?( page ).should be_false
                        end
                    end
                end
            end

            context String do
                context 'and #skip_path? returns' do
                    context 'true' do
                        it 'returns true' do
                            subject.stub(:skip_path?){ true }
                            subject.skip_resource?( 'stuff' ).should be_true
                        end
                    end

                    context 'false' do
                        it 'returns false' do
                            subject.stub(:skip_path?){ false }
                            subject.skip_resource?( 'stuff' ).should be_false
                        end
                    end
                end
            end
        end
    end

    describe '#random_seed' do
        it 'returns a random string' do
            subject.random_seed.should be_kind_of String
        end
    end

    describe '#seconds_to_hms' do
        it 'converts seconds to HOURS:MINUTES:SECONDS' do
            subject.seconds_to_hms( 0 ).should == '00:00:00'
            subject.seconds_to_hms( 1 ).should == '00:00:01'
            subject.seconds_to_hms( 60 ).should == '00:01:00'
            subject.seconds_to_hms( 60*60 ).should == '01:00:00'
            subject.seconds_to_hms( 60*60 + 60 + 1 ).should == '01:01:01'
        end
    end

    describe '#hms_to_seconds' do
        it 'converts seconds to HOURS:MINUTES:SECONDS' do
            subject.hms_to_seconds( '00:00:00' ).should == 0
            subject.hms_to_seconds( '00:00:01' ).should == 1
            subject.hms_to_seconds( '00:01:00' ).should == 60
            subject.hms_to_seconds( '01:00:00' ).should == 60*60
            subject.hms_to_seconds( '01:01:01').should == 60 * 60 + 60 + 1
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
