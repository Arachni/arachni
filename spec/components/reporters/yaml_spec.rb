require 'spec_helper'

describe name_from_filename do
    include_examples 'reporter'

    test_with_full_report do
        full_report.to_h.to_yaml.recode.should ==
            IO.read( outfile ).force_encoding( 'UTF-8' )
    end

    test_with_empty_report do
        empty_report.to_h.to_yaml.should == IO.binread( outfile )
    end
end
