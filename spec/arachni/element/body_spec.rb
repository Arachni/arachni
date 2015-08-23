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

                    logged_issue = Arachni::Data.issues.first
                    expect(logged_issue).to be_truthy

                    expect(logged_issue.vector.url).to eq(Arachni::Utilities.normalize_url( @url ))
                    expect(logged_issue.vector.class).to eq(Arachni::Element::Body)
                    expect(logged_issue.signature).to eq(valid_pattern.source)
                    expect(logged_issue.proof).to eq('Match')
                    expect(logged_issue.trusted).to be_truthy
                end
            end

            context 'and it does not matche the given pattern' do
                it 'does not log an issue' do
                    auditable.match_and_log( invalid_pattern )
                    expect(Arachni::Data.issues).to be_empty
                end
            end
        end
    end

    describe '#dup' do
        it 'duplicates self' do
            body = auditable.dup
            expect(body).to eq(auditable)
            expect(body.object_id).not_to eq(auditable)
        end
    end

end
