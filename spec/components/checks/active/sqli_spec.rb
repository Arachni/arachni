require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(Oracle ColdFusion InterBase PostgreSQL MySQL MSSQL EMC
            SQLite DB2 Informix Firebird MaxDB Sybase Frontbase Ingres HSQLDB)
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header ]
    end

    def issue_count_per_element
        {
            Element::Form   => 4,
            Element::Link   => 4,
            Element::Cookie => 4,
            Element::Header => 9
        }
    end

    easy_test
end
