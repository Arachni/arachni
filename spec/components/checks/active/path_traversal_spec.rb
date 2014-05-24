require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:unix, :windows, :tomcat]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header ]
    end

    def issue_count_per_element_per_platform
        {
            unix:    {
                Element::Form   => 112,
                Element::Link   => 112,
                Element::Cookie => 112,
                Element::Header => 56
            },
            windows: {
                Element::Form   => 168,
                Element::Link   => 168,
                Element::Cookie => 168,
                Element::Header => 84
            },
            tomcat:  {
                Element::Form   => 6,
                Element::Link   => 6,
                Element::Cookie => 6,
                Element::Header => 3
            },
        }
    end

    easy_test
end
