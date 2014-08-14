require 'spec_helper'

describe name_from_filename do
    include_examples 'reporter'

    test_with_full_report do
        json = IO.read( outfile ).force_encoding( 'UTF-8' )
        JSON.pretty_generate( full_report.to_hash ).should == json
        JSON.load( json ).is_a?( Hash ).should be_true
    end

    test_with_empty_report do
        json = IO.read( outfile )
        JSON.pretty_generate( empty_report.to_hash ).should == json
        JSON.load( json ).is_a?( Hash ).should be_true
    end
end
