require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    before( :each ){ framework.sitemap.clear }

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header ]
    end

    elements.each do |element|
        element = element.type

        it "probes #{element} elements" do
            # audit the current element type but don't expect any issues
            audit element, false

            urls = framework.sitemap
            urls.should include options.url + "#{element}/straight/trained"
            urls.should include options.url + "#{element}/append/trained"
        end
    end

    context 'when the link count limit has been reached' do
        it 'does not run' do
            framework.options.scope.page_limit = 4
            audit :form, false

            urls = framework.sitemap
            urls.should_not include "#{options.url}form/straight/trained"
            urls.should_not include "#{options.url}form/append/trained"
        end
    end

end
