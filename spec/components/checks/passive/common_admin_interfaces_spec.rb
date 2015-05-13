require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Server ]
    end

    def issue_count
        current_check.resources.count
    end

    easy_test
end
