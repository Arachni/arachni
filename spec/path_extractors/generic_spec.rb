require 'spec_helper'

describe name_from_filename do
    include_examples 'path_extractor'

    def results
        [
            'http://test.com',
            'https://test.com',
            'http://blah.com',
            'https://blah.com'
        ]
    end

    def text
        <<-HTML
            <script>
                var url  = 'http://test.com';
                var url2 = "https://test.com";
            </script>

            http://blah.com
            https://blah.com
        HTML
    end

    easy_test
end
