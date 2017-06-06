require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::NestedCookie,
          Element::Header, Element::LinkTemplate ]
    end

    def issue_count_per_element
        {
            Element::Form         => 12,
            Element::Link         => 13,
            Element::Cookie       => 14,
            Element::Header       => 6,
            Element::LinkTemplate => 12,
            Element::NestedCookie => 7
        }
    end

    easy_test
end
