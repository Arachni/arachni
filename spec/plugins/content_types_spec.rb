require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before ( :all ) do
        options.url = url
    end

    def results
        framework.plugins.results[name_from_filename][:results]
    end

    def default_results
        yaml_load <<YAML
---
image/png:
- :url: __URL__png
  :method: GET
  :params: {}
application/vnd.ms-excel:
- :url: __URL__excel
  :method: GET
  :params: {}
YAML
    end

    def results_with_options
        yaml_load <<YAML
---
text/html;charset=utf-8:
- :url: __URL__
  :method: GET
  :params: {}
text/css:
- :url: __URL__css
  :method: GET
  :params: {}
YAML
    end

    def results_with_empty_options
        yaml_load <<YAML
---
text/html;charset=utf-8:
- :url: __URL__
  :method: GET
  :params: {}
text/css:
- :url: __URL__css
  :method: GET
  :params: {}
image/png:
- :url: __URL__png
  :method: GET
  :params: {}
application/vnd.ms-excel:
- :url: __URL__excel
  :method: GET
  :params: {}
YAML
    end

    context 'with default options' do
        it "skips 'text' content types" do
            run
            results.should eq default_results
        end
    end

    context 'with custom \'exclude\' option' do
        it "skips the provided content types" do
            Arachni::Options.plugins = { name_from_filename => { 'exclude' => 'image|excel' } }
            run
            results.should eq results_with_options
        end
    end

    context 'with an empty \'exclude\' option' do
        it "logs everything" do
            Arachni::Options.plugins = { name_from_filename => { 'exclude' => '' } }
            run
            results.should eq results_with_empty_options
        end
    end

    describe '.merge' do
        it 'merges an array of results' do
            results = framework.plugins[name_from_filename].merge [ default_results, results_with_options ]
            results.should eq results_with_empty_options
        end
    end
end
