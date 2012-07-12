require_relative '../spec_helper'

describe name_from_filename do
	include_examples 'plugin'

	before( :all ) do
		Arachni::Options.url = url
	end

	context "when given the right params" do
		it 'should locate the form and login successfully' do
			name = name_from_filename

			Arachni::Options.plugins[name] = {
				'url'    => url + '/login',
				'params' => 'username=john&password=doe',
			}

			run

			results = results_for( name )
			results[:code].should == 1
			results[:msg].should  == framework.plugins[name]::MSG_SUCCESS
			results[:cookies]['success'].should == 'true'

			framework.sitemap.include?( url + 'congrats' ).should be_true
		end
	end

	context "when given invalid params" do
		it 'should complain about not being able to find the form' do
			name = name_from_filename

			Arachni::Options.plugins[name] = {
				'url'    => url + '/login',
				'params' => 'username2=john&password=doe',
			}

			run

			results = results_for( name )
			results[:code].should == 0
			results[:msg].start_with?( framework.plugins[name]::MSG_FAILURE ).should be_true
		end
	end
end
