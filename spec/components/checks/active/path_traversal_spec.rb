require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:unix, :windows, :tomcat]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate, Element::JSON ]
    end

    def issue_count_per_element_per_platform
        {
            unix:    {
                Element::Form         => 112,
                Element::Link         => 112,
                Element::Cookie       => 112,
                Element::Header       => 56,
                Element::LinkTemplate => 8,
                Element::JSON         => 168
            },
            windows: {
                Element::Form         => 336,
                Element::Link         => 336,
                Element::Cookie       => 336,
                Element::Header       => 168,
                Element::LinkTemplate => 24,
                Element::JSON         => 504
            },
            tomcat:  {
                Element::Form         => 8,
                Element::Link         => 8,
                Element::Cookie       => 8,
                Element::Header       => 4,
                Element::LinkTemplate => 0,
                Element::JSON         => 12
            }
        }
    end

    easy_test
end
