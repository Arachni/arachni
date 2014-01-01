require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.url = url
    end

    context 'when given the right params' do
        it 'locates the form and login successfully' do
            name = name_from_filename

            options.plugins[name] = {
                'url'    => url + '/login',
                'params' => 'username=john&password=doe',
                'check'  => 'Hi there logged-in user'
            }

            run

            results = results_for( name )
            results[:code].should == 1
            results[:msg].should  == framework.plugins[name]::MSG_SUCCESS
            results[:cookies]['success'].should == 'true'

            framework.sitemap.include?( url + 'congrats' ).should be_true
        end

        it 'should provide a login sequence and login check to the framework' do
            session.logged_in?.should be_true

            http.cookie_jar.clear

            session.logged_in?.should be_false
            session.login.should be_true
            session.logged_in?.should be_true
        end
    end

    context 'when given invalid params' do
        it 'complains about not being able to find the form' do
            name = name_from_filename

            options.plugins[name] = {
                'url'    => url + '/login',
                'params' => 'username2=john&password=doe',
                'check'  => 'Hi there logged-in user'
            }

            t = Thread.new { run }
            sleep 0.1 while !(results = results_for( name ))
            t.kill

            results[:code].should == 0
            results[:msg].start_with?( framework.plugins[name]::MSG_FAILURE ).should be_true
        end

        it 'does not resume the scan' do
            name = name_from_filename

            options.plugins[name] = {
                'url'    => url + '/login',
                'params' => 'username2=john&password=doe',
                'check'  => 'Hi there logged-in user'
            }

            t = Thread.new { run }
            sleep 0.1 while !results_for( name )

            framework.status.to_s.should == 'paused'
            t.kill
        end
    end

    context 'when the verifier does not match' do
        it 'complains about not being able to verify the login' do
            name = name_from_filename

            options.plugins[name] = {
                'url'    => url + '/login',
                'params' => 'username=john&password=doe',
                'check'  => 'Hi there Jimbo'
            }

            t = Thread.new { run }
            sleep 0.1 while !(results = results_for( name ))
            t.kill

            results[:code].should == -2
            results[:msg].start_with?( framework.plugins[name]::MSG_NO_MATCH ).should be_true
        end
    end
end
