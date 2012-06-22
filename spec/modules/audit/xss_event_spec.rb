require_relative '../../spec_helper'

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
            Element::LINK   => 140,
            Element::FORM   => 144,
            Element::COOKIE => 140,
            Element::HEADER => 140
        }
    end

    easy_test
end
