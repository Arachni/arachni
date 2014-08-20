require 'spec_helper'

describe name_from_filename do
    include_examples 'path_extractor'

    def results
        [
            'http://test.com',
            'test',
            'test.com',
            'iframe.com'
        ]
    end

    def text
        results[0...-1].map { |u| "<frame src='#{u}' />" }.join + "<iframe src='iframe.com' />"
    end

    easy_test
end
