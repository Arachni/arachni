require 'spec_helper'

describe name_from_filename do
    include_examples 'reporter'

    test_with_full_report do
        json = IO.read( outfile ).force_encoding( 'UTF-8' )
        expect(JSON.pretty_generate( full_report.to_hash )).to eq(json)
        expect(JSON.load( json ).is_a?( Hash )).to be_truthy
    end

    test_with_empty_report do
        json = IO.read( outfile )
        expect(JSON.pretty_generate( empty_report.to_hash )).to eq(json)
        expect(JSON.load( json ).is_a?( Hash )).to be_truthy
    end
end
