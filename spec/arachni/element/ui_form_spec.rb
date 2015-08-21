require 'spec_helper'

describe Arachni::Element::UIForm do
    html = '<button id="insert">Insert into DOM</button'

    subject do
        described_class.new(
            action: url,
            source: html,
            method: 'click'
        )
    end
    let(:url) { 'http://test.com/' }

    it_should_behave_like 'dom_only', html
end
