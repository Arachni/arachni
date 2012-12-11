require_relative '../spec_helper'

describe Arachni::Error do
    it 'should inherit from StandardError' do
        (Arachni::Error <= StandardError).should be_true

        begin
            fail Arachni::Error
        rescue Arachni::Error => e
            ap e
        end
    end
end
