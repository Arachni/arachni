require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:unix, :windows, :php, :perl, :java]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate, Element::JSON, Element::XML ]
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
                Element::XML          => 32
            },
            windows: {
                Element::Form         => 192,
                Element::Link         => 192,
                Element::Cookie       => 96,
                Element::Header       => 48,
                Element::LinkTemplate => 56,
                Element::JSON         => 96,
                Element::XML          => 192
            },
            java:    {
                Element::Form         => 16,
                Element::Link         => 16,
                Element::Cookie       => 8,
                Element::Header       => 4,
                Element::LinkTemplate => 8,
                Element::JSON         => 8,
                Element::XML          => 16
            },
            php:  {
                Element::Form         => 240,
                Element::Link         => 240,
                Element::Cookie       => 112,
                Element::Header       => 56,
                Element::LinkTemplate => 120,
                Element::JSON         => 112,
                Element::XML          => 224
            },
            perl:  {
                Element::Form         => 240,
                Element::Link         => 240,
                Element::Cookie       => 120,
                Element::Header       => 60,
                Element::LinkTemplate => 120,
                Element::JSON         => 120,
                Element::XML          => 240
            }
        }
    end

    easy_test
end
