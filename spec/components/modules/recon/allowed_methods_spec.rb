require 'spec_helper'

describe name_from_filename do
    include_examples 'module'

    def self.targets
        %w(Generic)
    end

    def self.elements
        [ Element::SERVER ]
    end

    def issue_count
        1
    end

    easy_test { issues.first.match.should == 'OPTIONS, TRACE, GET, HEAD' }
end
