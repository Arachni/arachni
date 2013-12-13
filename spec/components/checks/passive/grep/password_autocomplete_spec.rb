require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(Generic)
    end

    def self.elements
        [ Element::Form ]
    end

    def issue_count
        2
    end

    easy_test { issues.map { |i| i.vector.name_or_id }.sort.should == %w(insecure insecure_2).sort }
end
