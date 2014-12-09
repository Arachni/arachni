require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::JSON ]
    end

    def issue_count_per_element
        {
            Element::Form   => 16,
            Element::Link   => 16,
            Element::Cookie => 16,
            Element::Header => 8,
            Element::JSON   => 12
        }
    end

    easy_test
end
