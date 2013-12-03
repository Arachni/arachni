require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(Generic)
    end

    def self.elements
        [ Element::Path ]
    end

    def issue_count
        8
    end

    easy_test
end
