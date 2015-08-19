require 'spec_helper'

describe name_from_filename do
    include_examples 'reporter'

    test_with_full_report do
        expect(Marshal.dump( full_report.to_h )).to eq(IO.read( outfile ))
    end

    test_with_empty_report do
        expect(Marshal.dump( empty_report.to_h )).to eq(IO.read( outfile ))
    end
end
