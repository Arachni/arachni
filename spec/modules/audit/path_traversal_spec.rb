require 'spec_helper'

describe name_from_filename do
    include_examples 'module'

    def self.targets
        %w(Unix Windows Tomcat)
    end

    def self.elements
        [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ]
    end

    def issue_count_per_element_per_target
        {
            unix:    {
                Element::FORM => 8,
                Element::LINK => 8,
                Element::COOKIE => 8,
                Element::HEADER => 4
            },
            windows: {
                Element::FORM => 24,
                Element::LINK => 24,
                Element::COOKIE => 24,
                Element::HEADER => 12
            },
            tomcat:  {
                Element::FORM => 12,
                Element::LINK => 12,
                Element::COOKIE => 12,
                Element::HEADER => 6
            },
        }
    end

    easy_test
end
