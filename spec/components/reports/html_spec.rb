require 'spec_helper'

describe name_from_filename do
    include_examples 'reporter'

    test_with_full_report do
        Nokogiri::HTML( IO.read( outfile ) ).css( '.issue' ).should be_any
    end

    test_with_empty_report do
        Nokogiri::HTML( IO.read( outfile ) ).css( '.issue' ).should be_empty
    end
end
