require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::JSON, Element::XML ]
    end

    def issue_count_per_element
        {
            Element::Form   => 26,
            Element::Link   => 22,
            Element::Cookie => 11,
            Element::Header => 11,
            Element::JSON   => 9,
            Element::XML    => 18
        }
    end

    easy_test
end
