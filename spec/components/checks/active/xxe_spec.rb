require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:unix, :windows]
    end

    def self.elements
        [ Element::XML ]
    end

    def issue_count
        4
    end

    easy_test
end
