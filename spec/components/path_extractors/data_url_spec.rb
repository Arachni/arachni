require 'spec_helper'

describe name_from_filename do
    include_examples 'path_extractor'

    def results
        [
            'http://test.com',
            'test',
            'test.com'
        ]
    end

    def text
        <<EOHTML
        <a data-url='http://test.com'>1</a>
        <span data-url='test.com'>2</span>
        <div data-url='test'>2</div>
EOHTML
    end

    easy_test
end
