require_relative '../../spec_helper'

describe name_from_filename do
    include_examples 'module'

    def self.targets
        %w(Generic)
    end

    def self.elements
        [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ]
    end

    elements.each do |element|
        it "should probe #{element}s" do
            # audit the current element type but don't expect any issues
            audit element.to_sym, false

            urls = framework.auditstore.sitemap
            urls.include?( options.url + "#{element}/straight/trained" ).should be_true
            urls.include?( options.url + "#{element}/append/trained" ).should be_true
        end
    end

end
