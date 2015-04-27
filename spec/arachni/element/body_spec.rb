require 'spec_helper'

describe Arachni::Element::Body do
    it_should_behave_like 'element'
    it_should_behave_like 'with_auditor'

    before :each do
        @url  = web_server_url_for( :body )
        @framework ||= Arachni::Framework.new
        @page = Arachni::Page.from_url( @url )
        @auditor = Auditor.new( @page, @framework )
    end

    after :each do
        @framework.clean_up
        @framework.reset
        reset_options
    end

    subject do
        described_class.new( @page.url )
    end

    let(:auditor) { @auditor }
    let(:auditable) do
        s = subject.dup
        s.auditor = auditor
        s
    end

    let(:valid_pattern) { /match/i }
    let(:invalid_pattern) { /will not match/ }

    describe '#match_and_log' do
        context 'when defaulting to current page' do
            context 'and it matches the given pattern' do
                it 'logs an issue' do
                    auditable.match_and_log( valid_pattern )

                    logged_issue = Arachni::Data.issues.flatten.first
                    logged_issue.should be_true

                    logged_issue.vector.url.should == Arachni::Utilities.normalize_url( @url )
                    logged_issue.vector.class.should == Arachni::Element::Body
                    logged_issue.signature.should == valid_pattern.source
                    logged_issue.proof.should == 'Match'
                    logged_issue.trusted.should be_true
                end
            end

            context 'and it does not matche the given pattern' do
                it 'does not log an issue' do
                    auditable.match_and_log( invalid_pattern )
                    Arachni::Data.issues.should be_empty
                end
            end
        end
    end

    describe '#dup' do
        it 'duplicates self' do
            body = auditable.dup
            body.should == auditable
            body.object_id.should_not == auditable
        end
    end

end
