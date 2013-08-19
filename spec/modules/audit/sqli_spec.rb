require 'spec_helper'

describe name_from_filename do
    include_examples 'module'

    def self.targets
        %w(Oracle ColdFusion InterBase PostgreSQL MySQL MSSQL EMC SQLite DB2 Informix Firebird)
    end

    def self.elements
        [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ]
    end

    def issue_count_per_element
        {
            Element::FORM   => 4,
            Element::LINK   => 4,
            Element::COOKIE => 3,
            Element::HEADER => 9
        }
    end

    easy_test
end
