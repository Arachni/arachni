require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.targets
        %w(Generic)
    end

    def self.elements
        [ Element::FORM ]
    end

    before( :each ) do
        http.cookie_jar << Arachni::Element::Cookie.new(
            url: url,
            inputs: { 'logged_in' => 'true' }
        )
    end

    it 'logs forms that lack CSRF protection' do
        audit :forms
        issues.size.should == 1
        issues.first.var.should == 'insecure_important_form'
    end

    it 'skips forms that have an anti-CSRF token in a name attribute' do
        options.url = url + 'token_in_name'
        audit :forms
        issues.size.should == 1
        issues.first.var.should == 'insecure_important_form'
    end

    it 'skips forms that have an anti-CSRF token in their action URL' do
        options.url = url + 'token_in_action'
        audit :forms
        issues.size.should == 1
        issues.first.var.should == 'insecure_important_form'
    end

    it 'skips forms that have a nonce' do
        options.url = url + 'with_nonce'
        audit :forms
        issues.size.should == 1
        issues.first.var.should == 'insecure_important_form'
    end

end
