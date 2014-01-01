require 'spec_helper'

describe name_from_filename do
    include_examples 'module'

    def self.targets
        %w(PHP JSP ASP)
    end

    def self.elements
        [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ]
    end

    def issue_count_per_element
        {
            Element::FORM   => 6,
            Element::LINK   => 10,
            Element::COOKIE => 3,
            Element::HEADER => 6
        }
    end

    easy_test
end
