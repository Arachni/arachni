require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form ]
    end

    before( :each ) do
        http.cookie_jar << Arachni::Element::Cookie.new(
            url: url,
            inputs: { 'logged_in' => 'true' }
        )
    end

    it 'skips forms that have a nonce' do
        options.url = url
        audit :forms
        expect(issues.size).to eq(1)
        expect(issues.first.vector.name).to eq('insecure_important_form')
    end

end
