require_relative '../spec_helper'

describe name_from_filename do
    include_examples 'report'

    test_with_full_report do
        Nokogiri::XML( IO.read( outfile ) ).css( 'issue' ).size.should == full_report.issues.size
    end

    test_with_empty_report do
        Nokogiri::XML( IO.read( outfile ) ).css( 'issue' ).size.should == empty_report.issues.size
    end
end
