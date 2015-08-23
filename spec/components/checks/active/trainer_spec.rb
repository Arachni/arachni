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
            expect(urls).to include options.url + "#{element}/straight/trained"
            expect(urls).to include options.url + "#{element}/append/trained"
        end
    end

    context 'when the link count limit has been reached' do
        it 'does not run' do
            framework.options.scope.page_limit = 4
            audit :form, false

            urls = framework.sitemap
            expect(urls).not_to include "#{options.url}header/straight/trained"
            expect(urls).not_to include "#{options.url}header/append/trained"
        end
    end

end
