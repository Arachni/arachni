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
            Element::FORM   => 2,
            Element::LINK   => 4,
            Element::COOKIE => 1,
            Element::HEADER => 1
        }
    end

    easy_test
end
