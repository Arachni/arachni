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
                Element::Form         => 224,
                Element::Link         => 224,
                Element::Cookie       => 112,
                Element::Header       => 56,
                Element::LinkTemplate => 16,
                Element::JSON         => 168,
                Element::XML          => 112
            },
            windows: {
                Element::Form         => 672,
                Element::Link         => 672,
                Element::Cookie       => 336,
                Element::Header       => 168,
                Element::LinkTemplate => 48,
                Element::JSON         => 504,
                Element::XML          => 336
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
