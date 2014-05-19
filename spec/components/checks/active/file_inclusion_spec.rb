require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:unix, :windows, :tomcat, :php, :perl]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate ]
    end

    def issue_count_per_element_per_platform
        {
            unix:    {
                Element::Form         => 16,
                Element::Link         => 16,
                Element::Cookie       => 16,
                Element::Header       => 8,
                Element::LinkTemplate => 16
            },
            windows: {
                Element::Form         => 48,
                Element::Link         => 48,
                Element::Cookie       => 48,
                Element::Header       => 24,
                Element::LinkTemplate => 48
            },
            tomcat:  {
                Element::Form         => 4,
                Element::Link         => 4,
                Element::Cookie       => 4,
                Element::Header       => 2,
                Element::LinkTemplate => 4
            },
            php:  {
                Element::Form         => 68,
                Element::Link         => 68,
                Element::Cookie       => 68,
                Element::Header       => 34,
                Element::LinkTemplate => 68
            },
            perl:  {
                Element::Form         => 68,
                Element::Link         => 68,
                Element::Cookie       => 68,
                Element::Header       => 34,
                Element::LinkTemplate => 68
            }
        }
    end

    easy_test
end
