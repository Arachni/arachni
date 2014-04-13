require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.url = url
    end

    context 'when given the right params' do
        it 'locates the form and login successfully' do
            options.plugins[component_name] = {
                'url'        => url + '/login',
                'parameters' => 'username=john&password=doe',
                'check'      => 'Hi there logged-in user'
            }

            run

            actual_results[:status].should  == :ok
            actual_results[:message].should == plugin::STATUSES[:ok]
            actual_results[:cookies]['success'].should == 'true'

            framework.sitemap.include?( url + 'congrats' ).should be_true
        end

        it 'provides a login sequence and login check to the framework' do
            options.plugins[component_name] = {
                'url'        => url + '/login',
                'parameters' => 'username=john&password=doe',
                'check'      => 'Hi there logged-in user'
            }

            run

            session.logged_in?.should be_true

            http.cookie_jar.clear

            session.logged_in?.should be_false
            session.login.should be_true
            session.logged_in?.should be_true
        end
    end

    context 'when given invalid params' do
        it 'complains about not being able to find the form' do
            options.plugins[component_name] = {
                'url'        => url + '/login',
                'parameters' => 'username2=john&password=doe',
                'check'      => 'Hi there logged-in user'
            }

            t = Thread.new { run }
            sleep 0.1 while !actual_results
            t.kill

            actual_results[:status].should  == :form_not_found
            actual_results[:message].should == plugin::STATUSES[:form_not_found]
        end

        it 'does not resume the scan' do
            options.plugins[component_name] = {
                'url'        => url + '/login',
                'parameters' => 'username2=john&password=doe',
                'check'      => 'Hi there logged-in user'
            }

            t = Thread.new { run }
            sleep 0.1 while !actual_results

            framework.status.to_s.should == 'paused'
            t.kill
        end
    end

    context 'when the verifier does not match' do
        it 'complains about not being able to verify the login' do
            options.plugins[component_name] = {
                'url'        => url + '/login',
                'parameters' => 'username=john&password=doe',
                'check'      => 'Hi there Jimbo'
            }

            t = Thread.new { run }
            sleep 0.1 while !actual_results
            t.kill

            actual_results[:status].should  == :check_failed
            actual_results[:message].should == plugin::STATUSES[:check_failed]
        end
    end
end
