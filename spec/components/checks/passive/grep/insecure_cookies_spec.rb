require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Cookie ]
    end

    def issue_count
        3
    end

    easy_test { expect(issues.map { |i| i.vector.name }.sort).to eq %w(cookie cookie2 jscookie).sort }
end
