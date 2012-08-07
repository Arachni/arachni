require_relative '../spec_helper'

describe name_from_filename do
    include_examples 'report'

    test_with_full_report do
        full_report.should == Marshal.load( IO.read( outfile ) )
    end

    test_with_empty_report do
        empty_report.should == Marshal.load( IO.read( outfile ) )
    end
end
