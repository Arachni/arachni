require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    before( :each ){ framework.sitemap.clear }

    def self.targets
        %w(Generic)
    end

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header ]
    end

    elements.each do |element|
        element = element.type

        it "probes #{element} elements" do
            # audit the current element type but don't expect any issues
            audit element, false

            urls = framework.auditstore.sitemap
            urls.include?( options.url + "#{element}/straight/trained" ).should be_true
            urls.include?( options.url + "#{element}/append/trained" ).should be_true
        end
    end

    context 'when the link count limit has been reached' do
        it 'does not run' do
            framework.opts.link_count_limit = 0
            audit :form, false
            framework.auditstore.sitemap.should be_empty
        end
    end

end
