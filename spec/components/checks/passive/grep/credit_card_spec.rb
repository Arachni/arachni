require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Body ]
    end

    def issue_count
        3
    end

    easy_test { expect(issues.find(&:trusted?)).to be_nil }
end
