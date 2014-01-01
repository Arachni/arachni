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

    context 'when a filter has been specified' do
        it 'only logs cookies that match it' do
            name = name_from_filename

            options.plugins[name] = {
                'filter' => 'followed'
            }

            run

            results = results_for( name )
            results.size.should == 2
            results.map { |r| r[:cookies].keys }.flatten.
                uniq.sort.should == %w(link_followed)
        end
    end
end
