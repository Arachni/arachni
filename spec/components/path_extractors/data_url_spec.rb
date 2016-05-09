require 'spec_helper'

describe name_from_filename do
    include_examples 'path_extractor'

    def results
        [
            'http://test.com',
            'test',
            'test.com',
            'test.gr'
        ]
    end

    def text
        <<EOHTML
        <a class="test" data-url= 'http://test.com'>1</a> <span data-url= 'test.com'>2</span>
        <div data-url = 'test' id=blah>2</div> <p data-url=test.gr >3</p>
EOHTML
    end

    easy_test
end
