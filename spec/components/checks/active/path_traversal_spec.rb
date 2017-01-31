require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:unix, :windows, :java]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate, Element::JSON, Element::XML ]
    end

    def issue_count_per_element_per_platform
        {
            unix:    {
                Element::Form         => 288,
                Element::Link         => 288,
                Element::Cookie       => 144,
                Element::Header       => 72,
                Element::LinkTemplate => 16,
                Element::JSON         => 216,
                Element::XML          => 144
            },
            windows: {
                Element::Form         => 864,
                Element::Link         => 864,
                Element::Cookie       => 432,
                Element::Header       => 216,
                Element::LinkTemplate => 48,
                Element::JSON         => 648,
                Element::XML          => 432
            },
            java:    {
                Element::Form         => 16,
                Element::Link         => 16,
                Element::Cookie       => 8,
                Element::Header       => 4,
                Element::LinkTemplate => 0,
                Element::JSON         => 12,
                Element::XML          => 8
            }
        }
    end

    easy_test
end
