require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(PHP JSP ASP)
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header ]
    end

    def issue_count_per_element
        {
            Element::Form   => 6,
            Element::Link   => 10,
            Element::Cookie => 3,
            Element::Header => 3
        }
    end

    easy_test
end
