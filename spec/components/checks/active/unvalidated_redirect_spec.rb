require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::JSON, Element::XML ]
    end

    def issue_count_per_element
        {
            Element::Form   => 14,
            Element::Link   => 10,
            Element::Cookie => 5,
            Element::Header => 5,
            Element::JSON   => 3,
            Element::XML    => 6
        }
    end

    easy_test
end
