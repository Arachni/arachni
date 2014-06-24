require 'spec_helper'

describe name_from_filename do
    include_examples 'reporter'

    # Validates itself via the XSD.
    test_with_full_report
    test_with_empty_report
end
