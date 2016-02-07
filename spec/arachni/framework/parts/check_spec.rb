require 'spec_helper'

describe Arachni::Framework::Parts::Check do
    include_examples 'framework'

    describe '#checks' do
        it 'provides access to the check manager' do
            expect(subject.checks.is_a?( Arachni::Check::Manager )).to be_truthy
            expect(subject.checks.available).to eq(%w(signature))
        end
    end

    describe '#list_checks' do
        context 'when a glob is given' do
            it 'uses it to filter out checks that do not match it' do
                subject.list_checks( 'boo' ).size == 0

                expect(subject.list_checks( 'signature' )).to eq(subject.list_checks)
                subject.list_checks.size == 1
            end
        end
    end

end
