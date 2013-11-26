require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(Unix Windows Tomcat PHP Perl)
    end

    def self.elements
        [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ]
    end

    def issue_count_per_element_per_target
        {
            unix:    {
                Element::FORM   => 8,
                Element::LINK   => 8,
                Element::COOKIE => 8,
                Element::HEADER => 4
            },
            windows: {
                Element::FORM   => 24,
                Element::LINK   => 24,
                Element::COOKIE => 24,
                Element::HEADER => 12
            },
            tomcat:  {
                Element::FORM   => 4,
                Element::LINK   => 4,
                Element::COOKIE => 4,
                Element::HEADER => 2
            },
            php:  {
                Element::FORM   => 36,
                Element::LINK   => 36,
                Element::COOKIE => 36,
                Element::HEADER => 18
            },
            perl:  {
                Element::FORM   => 36,
                Element::LINK   => 36,
                Element::COOKIE => 36,
                Element::HEADER => 18
            }
        }
    end

    easy_test
end
