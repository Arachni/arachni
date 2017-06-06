require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::NestedCookie,
          Element::Header ]
    end

    def issue_count_per_element
        {
            Element::Form         => 5,
            Element::Link         => 5,
            Element::Cookie       => 10,
            Element::Header       => 5,
            Element::LinkTemplate => 5,
            Element::NestedCookie => 10
        }
    end

    easy_test
end
