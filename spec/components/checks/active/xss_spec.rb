require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate ]
    end

    def issue_count_per_element
        {
            Element::Form         => 9,
            Element::Link         => 10,
            Element::Cookie       => 9,
            Element::Header       => 8,
            Element::LinkTemplate => 9
        }
    end

    easy_test
end
