require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before(:all) do
        options.url = url
    end

    def default_results
        yaml_load <<YAML
---
image/png:
- url: __URL__png
  method: GET
  parameters: {}
application/vnd.ms-excel:
- url: __URL__excel
  method: GET
  parameters: {}
YAML
    end

    def results_with_options
        yaml_load <<YAML
---
text/html;charset=utf-8:
- url: __URL__
  method: GET
  parameters: {}
text/css:
- url: __URL__css
  method: GET
  parameters: {}
YAML
    end

    def results_with_empty_options
        yaml_load <<YAML
---
text/html;charset=utf-8:
- url: __URL__
  method: GET
  parameters: {}
text/css:
- url: __URL__css
  method: GET
  parameters: {}
image/png:
- url: __URL__png
  method: GET
  parameters: {}
application/vnd.ms-excel:
- url: __URL__excel
  method: GET
  parameters: {}
YAML
    end

    context 'with default options' do
        it "skips 'text' content types" do
            run
            expect(actual_results).to eq default_results
        end
    end

    context 'with custom \'exclude\' option' do
        it 'skips the provided content types' do
            options.plugins[component_name] = { 'exclude' => 'image|excel' }

            run
            expect(actual_results).to eq results_with_options
        end
    end

    context 'with an empty \'exclude\' option' do
        it 'logs everything' do
            options.plugins[component_name] = { 'exclude' => '' }

            run
            expect(actual_results).to eq results_with_empty_options
        end
    end

    describe '.merge' do
        it 'merges an array of results' do
            results = plugin.merge( [default_results, results_with_options] )
            expect(results).to eq results_with_empty_options
        end
    end
end
