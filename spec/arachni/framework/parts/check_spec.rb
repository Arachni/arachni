require 'spec_helper'

describe Arachni::Framework::Parts::Check do
    include_examples 'framework'

    describe '#checks' do
        it 'provides access to the check manager' do
            subject.checks.is_a?( Arachni::Check::Manager ).should be_true
            subject.checks.available.should == %w(taint)
        end
    end

    describe '#list_checks' do
        context 'when a pattern is given' do
            it 'uses it to filter out checks that do not match it' do
                subject.list_checks( 'boo' ).size == 0

                subject.list_checks( 'taint' ).should == subject.list_checks
                subject.list_checks.size == 1
            end
        end
    end

end
