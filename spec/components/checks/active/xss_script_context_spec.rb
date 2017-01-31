require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate ]
    end

    def issue_count_per_element
        {
            Element::Form         => 64,
            Element::Link         => 32,
            Element::Cookie       => 32,
            Element::Header       => 24,
            Element::LinkTemplate => 18
        }
    end

    easy_test
end
