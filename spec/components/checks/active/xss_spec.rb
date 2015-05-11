require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate ]
    end

    def issue_count_per_element
        {
            Element::Link         => 7,
            Element::Form         => 6,
            Element::Cookie       => 6,
            Element::Header       => 5,
            Element::LinkTemplate => 6
        }
    end

    easy_test
end
