require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate, Element::JSON, Element::XML ]
    end

    def issue_count_per_element
        {
            Element::Form         => 4,
            Element::Link         => 4,
            Element::Cookie       => 4,
            Element::Header       => 2,
            Element::LinkTemplate => 8,
            Element::JSON         => 4,
            Element::XML          => 4
        }
    end

    easy_test
end
