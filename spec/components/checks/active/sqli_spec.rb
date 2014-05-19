require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.platforms
        [:access, :coldfusion, :db2, :emc, :firebird, :frontbase, :hsqldb,
         :informix, :ingres, :interbase, :maxdb, :mssql, :mysql, :oracle,
         :pgsql, :sqlite, :sybase]
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate ]
    end

    def issue_count_per_element_per_platform
        {
            access:     {
                Element::Form         => 12,
                Element::Link         => 12,
                Element::Cookie       => 6,
                Element::Header       => 6,
                Element::LinkTemplate => 6
            },
            coldfusion: {
                Element::Form         => 4,
                Element::Link         => 4,
                Element::Cookie       => 2,
                Element::Header       => 2,
                Element::LinkTemplate => 2
            },
            db2:        {
                Element::Form         => 16,
                Element::Link         => 16,
                Element::Cookie       => 8,
                Element::Header       => 8,
                Element::LinkTemplate => 8
            },
            emc:        {
                Element::Form         => 8,
                Element::Link         => 8,
                Element::Cookie       => 4,
                Element::Header       => 4,
                Element::LinkTemplate => 4
            },
            firebird:   {
                Element::Form         => 4,
                Element::Link         => 4,
                Element::Cookie       => 2,
                Element::Header       => 2,
                Element::LinkTemplate => 2
            },
            frontbase:  {
                Element::Form         => 4,
                Element::Link         => 4,
                Element::Cookie       => 2,
                Element::Header       => 2,
                Element::LinkTemplate => 2
            },
            hsqldb:     {
                Element::Form         => 4,
                Element::Link         => 4,
                Element::Cookie       => 2,
                Element::Header       => 2,
                Element::LinkTemplate => 2
            },
            informix:   {
                Element::Form         => 12,
                Element::Link         => 12,
                Element::Cookie       => 6,
                Element::Header       => 6,
                Element::LinkTemplate => 6
            },
            ingres:     {
                Element::Form         => 12,
                Element::Link         => 12,
                Element::Cookie       => 6,
                Element::Header       => 6,
                Element::LinkTemplate => 6
            },
            interbase:  {
                Element::Form         => 8,
                Element::Link         => 8,
                Element::Cookie       => 4,
                Element::Header       => 4,
                Element::LinkTemplate => 4
            },
            maxdb:      {
                Element::Form         => 4,
                Element::Link         => 4,
                Element::Cookie       => 2,
                Element::Header       => 2,
                Element::LinkTemplate => 2
            },
            mssql:      {
                Element::Form         => 86,
                Element::Link         => 86,
                Element::Cookie       => 42,
                Element::Header       => 42,
                Element::LinkTemplate => 42
            },
            mysql:      {
                Element::Form         => 52,
                Element::Link         => 52,
                Element::Cookie       => 26,
                Element::Header       => 26,
                Element::LinkTemplate => 26
            },
            oracle:     {
                Element::Form         => 20,
                Element::Link         => 20,
                Element::Cookie       => 10,
                Element::Header       => 10,
                Element::LinkTemplate => 10
            },
            pgsql:      {
                Element::Form         => 36,
                Element::Link         => 36,
                Element::Cookie       => 18,
                Element::Header       => 18,
                Element::LinkTemplate => 18
            },
            sqlite:     {
                Element::Form         => 16,
                Element::Link         => 16,
                Element::Cookie       => 8,
                Element::Header       => 8,
                Element::LinkTemplate => 8
            },
            sybase:     {
                Element::Form         => 12,
                Element::Link         => 12,
                Element::Cookie       => 6,
                Element::Header       => 6,
                Element::LinkTemplate => 6
            }
        }
    end

    easy_test
end
