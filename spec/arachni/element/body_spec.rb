require 'spec_helper'

describe Arachni::Element::Body do

    before :each do
        @framework.reset if @framework
        @framework = Arachni::Framework.new
    end

    before :all do
        @url  = web_server_url_for( :body )
        @page = Arachni::Page.from_url( @url )

        @auditor = Auditor.new( @page, Arachni::Framework.new )

        @body = described_class.new( @page )
        @body.auditor = @auditor
    end

    let(:valid_pattern) { /match/i }
    let(:invalid_pattern) { /will not match/ }

    describe '#match_and_log' do
        context 'when defaulting to current page' do
            context 'and it matches the given pattern' do
                it 'logs an issue' do
                    @body.match_and_log( valid_pattern )

                    logged_issue = @framework.checks.results.first
                    logged_issue.should be_true

                    logged_issue.vector.url.should == Arachni::Utilities.normalize_url( @url )
                    logged_issue.vector.class.should == Arachni::Element::Body
                    logged_issue.signature.should == valid_pattern.to_s
                    logged_issue.proof.should == 'Match'
                    logged_issue.trusted.should be_true
                end
            end

            context 'and it does not matche the given pattern' do
                it 'does not log an issue' do
                    @body.match_and_log( invalid_pattern )
                    @framework.checks.results.should be_empty
                end
            end
        end
    end

    describe '#dup' do
        it 'duplicates self' do
            body = @body.dup
            body.should == @body
            body.object_id.should_not == @body
        end
    end

    describe '#to_h' do
        it 'returns a hash' do
            @body.to_h.should == {
                type: :body,
                url:  @page.url
            }
        end
    end
end
