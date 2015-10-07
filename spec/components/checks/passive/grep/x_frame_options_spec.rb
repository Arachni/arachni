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
        expect(issues).to be_any
    end

    it 'does not log hosts with the header' do
        options.url = "#{url}/safe"
        run
        expect(issues).to be_empty
    end
end
