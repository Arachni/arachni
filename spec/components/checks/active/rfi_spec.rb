require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::NestedCookie,
          Element::Header, Element::JSON, Element::XML ]
    end

    def issue_count_per_element
        {
            Element::Form         => 24,
            Element::Link         => 24,
            Element::Cookie       => 18,
            Element::Header       => 6,
            Element::JSON         => 12,
            Element::XML          => 12,
            Element::NestedCookie => 24
        }
    end

    easy_test
end
