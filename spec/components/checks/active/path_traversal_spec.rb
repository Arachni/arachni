require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(Unix Windows Tomcat)
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header ]
    end

    def issue_count_per_element_per_target
        {
            unix:    {
                Element::Form => 56,
                Element::Link => 56,
                Element::Cookie => 56,
                Element::Header => 27
            },
            windows: {
                Element::Form => 84,
                Element::Link => 84,
                Element::Cookie => 84,
                Element::Header => 42
            },
            tomcat:  {
                Element::Form => 6,
                Element::Link => 6,
                Element::Cookie => 6,
                Element::Header => 3
            },
        }
    end

    easy_test
end
