require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:php, :asp, :jsp]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate, Element::JSON, Element::XML ]
    end

    def issue_count_per_element
        {
            Element::Form         => 6,
            Element::Link         => 6,
            Element::Cookie       => 3,
            Element::Header       => 3,
            Element::LinkTemplate => 5,
            Element::JSON         => 6,
            Element::XML          => 16
        }
    end

    easy_test
end
