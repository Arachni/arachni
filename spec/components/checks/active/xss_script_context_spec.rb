require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate ]
    end

    def issue_count_per_element
        {
            Element::Form   => 14,
            Element::Link   => 14,
            Element::Cookie => 14,
            Element::Header => 10,
            Element::LinkTemplate => 1
        }
    end

    easy_test
end
