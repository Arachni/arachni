require_relative '../spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.url = url
    end

    it 'should log the expected results' do
        run

        results = results_for( name_from_filename )

        results.size.should == 3

        results[0][:res]['effective_url'].should == url
        results[0][:cookies].should == { 'cookie1' => 'val1' }

        results[1][:res]['effective_url'].should == url + 'a_link'
        results[1][:cookies].should == { 'link_followed' => 'yay link!' }

        results[2][:res]['effective_url'].should == url + 'update_cookie'
        results[2][:cookies].should == { 'link_followed' => 'updated link!', 'stuff' => 'blah' }
    end
end
