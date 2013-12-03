require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(Unix Windows Tomcat PHP Perl)
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header ]
    end

    def issue_count_per_element_per_target
        {
            unix:    {
                Element::Form   => 8,
                Element::Link   => 8,
                Element::Cookie => 8,
                Element::Header => 4
            },
            windows: {
                Element::Form   => 24,
                Element::Link   => 24,
                Element::Cookie => 24,
                Element::Header => 12
            },
            tomcat:  {
                Element::Form   => 4,
                Element::Link   => 4,
                Element::Cookie => 4,
                Element::Header => 2
            },
            php:  {
                Element::Form   => 36,
                Element::Link   => 36,
                Element::Cookie => 36,
                Element::Header => 18
            },
            perl:  {
                Element::Form   => 36,
                Element::Link   => 36,
                Element::Cookie => 36,
                Element::Header => 18
            }
        }
    end

    easy_test
end
