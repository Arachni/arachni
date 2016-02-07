require 'spec_helper'

describe name_from_filename do
    include_examples 'path_extractor'

    def results
        [
            'http://test.com',
            'http://test.com/ /d',
            'test.com',
            'http://test2.com'
        ]
    end

    def text
        <<-HTML
            <meta http-equiv="refresh" content="5">
            <meta http-equiv="refreSH" content="5;URL='test.com'">
            <meta http-equiv="Refresh" content='0;URL="http://test.com"'>
            <meta http-equiv="Refresh" content='0;URL="http://test.com/ /d"'>
            <meta http-equiv="refResh" content='0;URL= http://test2.com '>
        HTML
    end

    easy_test
end
