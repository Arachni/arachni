require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:mysql, :mssql, :pgsql]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate, Element::JSON, Element::XML ]
    end

    def issue_count_per_element_per_platform
        {
            mysql: {
                Element::Form         => 16,
                Element::Link         => 16,
                Element::Cookie       => 16,
                Element::Header       => 16,
                Element::LinkTemplate => 16,
                Element::JSON         => 16,
                Element::XML          => 32
            },
            pgsql: {
                Element::Form         => 6,
                Element::Link         => 6,
                Element::Cookie       => 6,
                Element::Header       => 6,
                Element::LinkTemplate => 6,
                Element::JSON         => 6,
                Element::XML          => 12
            },
            mssql: {
                Element::Form         => 9,
                Element::Link         => 9,
                Element::Cookie       => 9,
                Element::Header       => 9,
                Element::LinkTemplate => 9,
                Element::JSON         => 9,
                Element::XML          => 18
            }
        }
    end

    easy_test
end
