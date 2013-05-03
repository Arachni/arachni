require 'spec_helper'

describe name_from_filename do
    include_examples 'module'

    def self.targets
        %w(Generic)
    end

    def self.elements
        [ Element::PATH ]
    end

    def issue_count
        current_module.filenames.count
    end

    easy_test
end
