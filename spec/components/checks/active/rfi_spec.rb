require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::JSON, Element::XML ]
    end

    def issue_count_per_element
        {
            Element::Form   => 24,
            Element::Link   => 24,
            Element::Cookie => 12,
            Element::Header => 6,
            Element::JSON   => 12,
            Element::XML    => 12
        }
    end

    easy_test
end
