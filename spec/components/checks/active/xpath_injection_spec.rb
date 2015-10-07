require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate, Element::JSON, Element::XML ]
    end

    def issue_count_per_element
        {
            Element::Form         => 125,
            Element::Link         => 125,
            Element::Cookie       => 150,
            Element::Header       => 75,
            Element::LinkTemplate => 75,
            Element::JSON         => 75,
            Element::XML          => 150
        }
    end

    easy_test
end
