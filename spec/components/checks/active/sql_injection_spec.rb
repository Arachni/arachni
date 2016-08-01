require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:access, :db2, :emc, :firebird, :frontbase, :hsqldb, :informix, :ingres,
         :interbase, :maxdb, :mssql, :mysql, :oracle, :pgsql, :sqlite, :sybase, :java]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate, Element::JSON, Element::XML ]
    end

    def issue_count_per_element_per_platform
        {
            access:     {
                Element::Form         => 15,
                Element::Link         => 15,
                Element::Cookie       => 12,
                Element::Header       => 6,
                Element::LinkTemplate => 12,
                Element::JSON         => 12,
                Element::XML          => 12
            },
            db2:        {
                Element::Form         => 15,
                Element::Link         => 15,
                Element::Cookie       => 12,
                Element::Header       => 6,
                Element::LinkTemplate => 12,
                Element::JSON         => 12,
                Element::XML          => 12
            },
            emc:        {
                Element::Form         => 10,
                Element::Link         => 10,
                Element::Cookie       => 8,
                Element::Header       => 4,
                Element::LinkTemplate => 8,
                Element::JSON         => 8,
                Element::XML          => 8
            },
            firebird:   {
                Element::Form         => 5,
                Element::Link         => 5,
                Element::Cookie       => 4,
                Element::Header       => 2,
                Element::LinkTemplate => 4,
                Element::JSON         => 4,
                Element::XML          => 4
            },
            frontbase:  {
                Element::Form         => 5,
                Element::Link         => 5,
                Element::Cookie       => 4,
                Element::Header       => 2,
                Element::LinkTemplate => 4,
                Element::JSON         => 4,
                Element::XML          => 4
            },
            hsqldb:     {
                Element::Form         => 5,
                Element::Link         => 5,
                Element::Cookie       => 4,
                Element::Header       => 2,
                Element::LinkTemplate => 4,
                Element::JSON         => 4,
                Element::XML          => 4
            },
            informix:   {
                Element::Form         => 15,
                Element::Link         => 15,
                Element::Cookie       => 12,
                Element::Header       => 6,
                Element::LinkTemplate => 12,
                Element::JSON         => 12,
                Element::XML          => 12
            },
            ingres:     {
                Element::Form         => 15,
                Element::Link         => 15,
                Element::Cookie       => 12,
                Element::Header       => 6,
                Element::LinkTemplate => 12,
                Element::JSON         => 12,
                Element::XML          => 12
            },
            interbase:  {
                Element::Form         => 10,
                Element::Link         => 10,
                Element::Cookie       => 8,
                Element::Header       => 4,
                Element::LinkTemplate => 8,
                Element::JSON         => 8,
                Element::XML          => 8
            },
            maxdb:      {
                Element::Form         => 5,
                Element::Link         => 5,
                Element::Cookie       => 4,
                Element::Header       => 2,
                Element::LinkTemplate => 4,
                Element::JSON         => 4,
                Element::XML          => 4
            },
            mssql:      {
                Element::Form         => 97,
                Element::Link         => 97,
                Element::Cookie       => 78,
                Element::Header       => 38,
                Element::LinkTemplate => 76,
                Element::JSON         => 78,
                Element::XML          => 76
            },
            mysql:      {
                Element::Form         => 65,
                Element::Link         => 65,
                Element::Cookie       => 52,
                Element::Header       => 26,
                Element::LinkTemplate => 52,
                Element::JSON         => 52,
                Element::XML          => 52
            },
            oracle:     {
                Element::Form         => 25,
                Element::Link         => 25,
                Element::Cookie       => 20,
                Element::Header       => 10,
                Element::LinkTemplate => 20,
                Element::JSON         => 20,
                Element::XML          => 20
            },
            pgsql:      {
                Element::Form         => 45,
                Element::Link         => 45,
                Element::Cookie       => 36,
                Element::Header       => 18,
                Element::LinkTemplate => 36,
                Element::JSON         => 36,
                Element::XML          => 36
            },
            sqlite:     {
                Element::Form         => 20,
                Element::Link         => 20,
                Element::Cookie       => 16,
                Element::Header       => 8,
                Element::LinkTemplate => 16,
                Element::JSON         => 16,
                Element::XML          => 16
            },
            sybase:     {
                Element::Form         => 15,
                Element::Link         => 15,
                Element::Cookie       => 12,
                Element::Header       => 6,
                Element::LinkTemplate => 12,
                Element::JSON         => 12,
                Element::XML          => 12
            },
            java:       {
                Element::Form         => 10,
                Element::Link         => 10,
                Element::Cookie       => 8,
                Element::Header       => 4,
                Element::LinkTemplate => 8,
                Element::JSON         => 8,
                Element::XML          => 8
            }
        }
    end

    easy_test
end
