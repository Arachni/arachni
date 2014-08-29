require 'spec_helper'

describe name_from_filename do
    include_examples 'reporter'

    # Not much to test here, if there's not an exception then we're cool.
    test_with_full_report
    test_with_empty_report
end
