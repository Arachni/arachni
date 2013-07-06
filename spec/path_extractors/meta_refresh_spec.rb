require 'spec_helper'

describe name_from_filename do
    include_examples 'path_extractor'

    def results
        [
            'http://test.com',
            'test.com',
            'http://test2.com'
        ]
    end

    def text
        <<-HTML
            <meta http-equiv="refresh" content="5">
            <meta http-equiv="refresh" content="5;URL='test.com'">
            <meta http-equiv="refresh" content='0;URL="http://test.com"'>
            <meta http-equiv="refresh" content='0;URL=http://test2.com'>
        HTML
    end

    easy_test
end
