require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate ]
    end

    def issue_count_per_element
        {
            Element::Form         => 15,
            Element::Link         => 15,
            Element::Cookie       => 15,
            Element::Header       => 11,
            Element::LinkTemplate => 8
        }
    end

    easy_test
end
