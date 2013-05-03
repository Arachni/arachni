require 'spec_helper'

describe name_from_filename do
    include_examples 'module'

    def self.targets
        %w(Unix Windows)
    end

    def self.elements
        [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ]
    end

    def issue_count_per_element
        {
            Element::FORM   => 10,
            Element::LINK   => 10,
            Element::COOKIE => 10,
            Element::HEADER => 9
        }
    end

    easy_test
end
