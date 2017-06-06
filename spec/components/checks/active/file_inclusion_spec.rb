require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:unix, :windows, :php, :perl, :java]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::NestedCookie,
          Element::Header, Element::LinkTemplate, Element::JSON, Element::XML ]
    end

    def issue_count_per_element_per_platform
        {
            unix:    {
                Element::Form         => 32,
                Element::Link         => 32,
                Element::Cookie       => 16,
                Element::Header       => 8,
                Element::LinkTemplate => 16,
                Element::JSON         => 16,
                Element::XML          => 16,
                Element::NestedCookie => 32
            },
            windows: {
                Element::Form         => 192,
                Element::Link         => 190,
                Element::Cookie       => 96,
                Element::Header       => 48,
                Element::LinkTemplate => 96,
                Element::JSON         => 96,
                Element::XML          => 96,
                Element::NestedCookie => 192
            },
            java:    {
                Element::Form         => 16,
                Element::Link         => 16,
                Element::Cookie       => 8,
                Element::Header       => 4,
                Element::LinkTemplate => 8,
                Element::JSON         => 8,
                Element::XML          => 8,
                Element::NestedCookie => 16
            },
            php:  {
                Element::Form         => 240,
                Element::Link         => 238,
                Element::Cookie       => 112,
                Element::Header       => 56,
                Element::LinkTemplate => 120,
                Element::JSON         => 112,
                Element::XML          => 112,
                Element::NestedCookie => 224
            },
            perl:  {
                Element::Form         => 240,
                Element::Link         => 238,
                Element::Cookie       => 120,
                Element::Header       => 60,
                Element::LinkTemplate => 120,
                Element::JSON         => 120,
                Element::XML          => 120,
                Element::NestedCookie => 240
            }
        }
    end

    easy_test
end
