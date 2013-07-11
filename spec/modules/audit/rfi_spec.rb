require 'spec_helper'

describe name_from_filename do
    include_examples 'module'

    def self.targets
        %w(Generic)
    end

    def self.elements
        [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ]
    end

    def issue_count_per_element
        {
            Element::FORM   => 8,
            Element::LINK   => 8,
            Element::COOKIE => 8,
            Element::HEADER => 4
        }
    end

    easy_test
end
