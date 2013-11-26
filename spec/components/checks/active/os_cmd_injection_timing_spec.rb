require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(Unix Windows)
    end

    def self.elements
        [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ]
    end

    def issue_count_per_element
        {
            Element::FORM   => 5,
            Element::LINK   => 5,
            Element::COOKIE => 5,
            Element::HEADER => 4
        }
    end

    easy_test
end
