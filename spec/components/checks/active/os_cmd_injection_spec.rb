require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:unix, :windows]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header ]
    end

    def issue_count_per_element
        {
            Element::Form   => 10,
            Element::Link   => 10,
            Element::Cookie => 10,
            Element::Header => 9
        }
    end

    easy_test
end
