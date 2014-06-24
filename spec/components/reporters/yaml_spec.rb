require 'spec_helper'

describe name_from_filename do
    include_examples 'reporter'

    test_with_full_report do
        full_report.should == YAML.load( IO.read( outfile ) )
    end

    test_with_empty_report do
        empty_report.should == YAML.load( IO.read( outfile ) )
    end
end
