require 'spec_helper'

describe Arachni::Error do
    it 'inherits from StandardError' do
        (Arachni::Error <= StandardError).should be_true

        caught = false
        begin
            fail Arachni::Error
        rescue StandardError => e
            caught = true
        end
        caught.should be_true

        caught = false
        begin
            fail Arachni::Error
        rescue
            caught = true
        end
        caught.should be_true
    end
end
