require 'spec_helper'

describe Arachni::Error do
    it 'inherits from StandardError' do
        expect(Arachni::Error <= StandardError).to be_truthy

        caught = false
        begin
            fail Arachni::Error
        rescue StandardError => e
            caught = true
        end
        expect(caught).to be_truthy

        caught = false
        begin
            fail Arachni::Error
        rescue
            caught = true
        end
        expect(caught).to be_truthy
    end
end
