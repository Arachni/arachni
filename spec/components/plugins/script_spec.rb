require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    it 'executes a Ruby script under the scope of the running plugin' do
        options.url = web_server_url_for(:framework)
        options.plugins[component_name] = { 'path' => fixtures_path + '/script_plugin.rb' }

        run
        expect(actual_results).to eq('I\'m a script!')
    end
end
