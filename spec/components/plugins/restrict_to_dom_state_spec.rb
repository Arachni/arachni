require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.url = url
    end

    it 'audits only the page at the specific DOM state' do
        options.plugins[component_name] = { 'fragment' => 'stuff/blah' }

        run
        expect(framework.sitemap).to eq({ "#{options.url}#stuff/blah" => 200 })
    end
end
