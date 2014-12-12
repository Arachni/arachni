require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::JSON, Element::XML ]
    end

    def issue_count_per_element
        {
            Element::Form   => 8,
            Element::Link   => 8,
            Element::Cookie => 8,
            Element::Header => 4,
            Element::JSON   => 4,
            Element::XML    => 8
        }
    end

    easy_test
end
