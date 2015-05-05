require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Server ]
    end

    def issue_count
        1
    end

    it 'logs hosts missing the header' do
        options.url = "#{url}/vulnerable"
        run
        issues.should be_any
    end

    it 'does not log hosts with the header' do
        options.url = "#{url}/safe"
        run
        issues.should be_empty
    end
end
