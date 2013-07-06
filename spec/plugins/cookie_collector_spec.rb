require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.url = url
    end

    it 'logs the expected results' do
        run

        results = results_for( name_from_filename )

        results.size.should == 3

        oks = 0
        results.each do |result|
            if (result[:res]['effective_url'] == url &&
                result[:cookies] == { 'cookie1' => 'val1' }) ||
                (result[:res]['effective_url'] == url + 'a_link' &&
                result[:cookies] == { 'link_followed' => 'yay link!' }) ||
                (result[:res]['effective_url'] == url + 'update_cookie' &&
                result[:cookies] == { 'link_followed' => 'updated link!', 'stuff' => 'blah' })
                oks += 1
            end

        end

        oks.should == 3
    end
end
