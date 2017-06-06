require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:access, :db2, :emc, :firebird, :frontbase, :hsqldb, :informix, :ingres,
         :interbase, :maxdb, :mssql, :mysql, :oracle, :pgsql, :sqlite, :sybase, :java]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::NestedCookie,
          Element::Header, Element::LinkTemplate, Element::JSON, Element::XML ]
    end

    def issue_count_per_element_per_platform
        {
            access:     {
                Element::Form         => 15,
                Element::Link         => 15,
                Element::Cookie       => 24,
                Element::Header       => 6,
                Element::LinkTemplate => 12,
                Element::JSON         => 12,
                Element::XML          => 12,
                Element::NestedCookie => 18
            },
            db2:        {
                Element::Form         => 15,
                Element::Link         => 15,
                Element::Cookie       => 24,
                Element::Header       => 6,
                Element::LinkTemplate => 12,
                Element::JSON         => 12,
                Element::XML          => 12,
                Element::NestedCookie => 18
            },
            emc:        {
                Element::Form         => 10,
                Element::Link         => 10,
                Element::Cookie       => 16,
                Element::Header       => 4,
                Element::LinkTemplate => 8,
                Element::JSON         => 8,
                Element::XML          => 8,
                Element::NestedCookie => 12
            },
            firebird:   {
                Element::Form         => 5,
                Element::Link         => 5,
                Element::Cookie       => 8,
                Element::Header       => 2,
                Element::LinkTemplate => 4,
                Element::JSON         => 4,
                Element::XML          => 4,
                Element::NestedCookie => 6
            },
            frontbase:  {
                Element::Form         => 5,
                Element::Link         => 5,
                Element::Cookie       => 8,
                Element::Header       => 2,
                Element::LinkTemplate => 4,
                Element::JSON         => 4,
                Element::XML          => 4,
                Element::NestedCookie => 6
            },
            hsqldb:     {
                Element::Form         => 5,
                Element::Link         => 5,
                Element::Cookie       => 8,
                Element::Header       => 2,
                Element::LinkTemplate => 4,
                Element::JSON         => 4,
                Element::XML          => 4,
                Element::NestedCookie => 6
            },
            informix:   {
                Element::Form         => 15,
                Element::Link         => 15,
                Element::Cookie       => 24,
                Element::Header       => 6,
                Element::LinkTemplate => 12,
                Element::JSON         => 12,
                Element::XML          => 12,
                Element::NestedCookie => 18
            },
            ingres:     {
                Element::Form         => 15,
                Element::Link         => 15,
                Element::Cookie       => 24,
                Element::Header       => 6,
                Element::LinkTemplate => 12,
                Element::JSON         => 12,
                Element::XML          => 12,
                Element::NestedCookie => 18
            },
            interbase:  {
                Element::Form         => 10,
                Element::Link         => 10,
                Element::Cookie       => 16,
                Element::Header       => 4,
                Element::LinkTemplate => 8,
                Element::JSON         => 8,
                Element::XML          => 8,
                Element::NestedCookie => 12
            },
            maxdb:      {
                Element::Form         => 5,
                Element::Link         => 5,
                Element::Cookie       => 8,
                Element::Header       => 2,
                Element::LinkTemplate => 4,
                Element::JSON         => 4,
                Element::XML          => 4,
                Element::NestedCookie => 6
            },
            mssql:      {
                Element::Form         => 97,
                Element::Link         => 97,
                Element::Cookie       => 156,
                Element::Header       => 38,
                Element::LinkTemplate => 76,
                Element::JSON         => 78,
                Element::XML          => 76,
                Element::NestedCookie => 116
            },
            mysql:      {
                Element::Form         => 65,
                Element::Link         => 65,
                Element::Cookie       => 104,
                Element::Header       => 26,
                Element::LinkTemplate => 52,
                Element::JSON         => 52,
                Element::XML          => 52,
                Element::NestedCookie => 78
            },
            oracle:     {
                Element::Form         => 25,
                Element::Link         => 25,
                Element::Cookie       => 40,
                Element::Header       => 10,
                Element::LinkTemplate => 20,
                Element::JSON         => 20,
                Element::XML          => 20,
                Element::NestedCookie => 30
            },
            pgsql:      {
                Element::Form         => 45,
                Element::Link         => 45,
                Element::Cookie       => 72,
                Element::Header       => 18,
                Element::LinkTemplate => 36,
                Element::JSON         => 36,
                Element::XML          => 36,
                Element::NestedCookie => 54
            },
            sqlite:     {
                Element::Form         => 20,
                Element::Link         => 20,
                Element::Cookie       => 32,
                Element::Header       => 8,
                Element::LinkTemplate => 16,
                Element::JSON         => 16,
                Element::XML          => 16,
                Element::NestedCookie => 24
            },
            sybase:     {
                Element::Form         => 15,
                Element::Link         => 15,
                Element::Cookie       => 24,
                Element::Header       => 6,
                Element::LinkTemplate => 12,
                Element::JSON         => 12,
                Element::XML          => 12,
                Element::NestedCookie => 18
            },
            java:       {
                Element::Form         => 10,
                Element::Link         => 10,
                Element::Cookie       => 16,
                Element::Header       => 4,
                Element::LinkTemplate => 8,
                Element::JSON         => 8,
                Element::XML          => 8,
                Element::NestedCookie => 12
            }
        }
    end

    easy_test
end
