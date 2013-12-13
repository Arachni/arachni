require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        @uniformals = [[],[]]
        10.times do |i|
            @uniformals[0] << Factory[:active_issue].
                tap { |issue| issue.vector.action += i.to_s }

            @uniformals[1] << Factory[:active_issue].
                tap { |issue| issue.vector.method = :stuff; issue.vector.action += i.to_s }
        end

        issue = Factory[:active_issue].tap { |issue| issue.vector.method = :stuff2 }

        framework.checks.register_results( @uniformals.flatten | [issue] )
    end

    it 'logs digests of issues which affect similar parameters across multipla pages' do
        run

        actual_results[0].sort.should == @uniformals[1].map(&:digest).sort
        actual_results[1].sort.should == @uniformals[0].map(&:digest).sort
    end
end
