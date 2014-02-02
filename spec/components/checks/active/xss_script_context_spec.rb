require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(Generic)
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header ]
    end

    def issue_count_per_element
        {
            Element::Form   => 2,
            Element::Link   => 2,
            Element::Cookie => 2,
            Element::Header => 1
        }
    end

    easy_test
end
