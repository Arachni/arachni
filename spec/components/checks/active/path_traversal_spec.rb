require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(Unix Windows Tomcat)
    end

    def self.elements
        [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ]
    end

    def issue_count_per_element_per_target
        {
            unix:    {
                Element::FORM => 56,
                Element::LINK => 56,
                Element::COOKIE => 56,
                Element::HEADER => 27
            },
            windows: {
                Element::FORM => 84,
                Element::LINK => 84,
                Element::COOKIE => 84,
                Element::HEADER => 42
            },
            tomcat:  {
                Element::FORM => 6,
                Element::LINK => 6,
                Element::COOKIE => 6,
                Element::HEADER => 3
            },
        }
    end

    easy_test
end
