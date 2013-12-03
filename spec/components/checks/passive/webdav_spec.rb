require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(Generic)
    end

    def self.elements
        [ Element::Server ]
    end

    def issue_count
        1
    end

    easy_test { issues.first.url.should == url }
end
