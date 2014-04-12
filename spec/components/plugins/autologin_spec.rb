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
                'url'        => url + '/login',
                'parameters' => 'username=john&password=doe',
                'check'      => 'Hi there logged-in user'
            }

            run

            results = results_for( name )

            results[:status].should  == :ok
            results[:message].should == framework.plugins[name]::STATUSES[:ok]
            results[:cookies]['success'].should == 'true'

            framework.sitemap.include?( url + 'congrats' ).should be_true
        end

        it 'provides a login sequence and login check to the framework' do
            name = name_from_filename

            options.plugins[name] = {
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
            name = name_from_filename

            options.plugins[name] = {
                'url'        => url + '/login',
                'parameters' => 'username2=john&password=doe',
                'check'      => 'Hi there logged-in user'
            }

            t = Thread.new { run }
            sleep 0.1 while !(results = results_for( name ))
            t.kill

            results[:status].should  == :form_not_found
            results[:message].should == framework.plugins[name]::STATUSES[:form_not_found]
        end

        it 'does not resume the scan' do
            name = name_from_filename

            options.plugins[name] = {
                'url'        => url + '/login',
                'parameters' => 'username2=john&password=doe',
                'check'      => 'Hi there logged-in user'
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
                'url'        => url + '/login',
                'parameters' => 'username=john&password=doe',
                'check'      => 'Hi there Jimbo'
            }

            t = Thread.new { run }
            sleep 0.1 while !(results = results_for( name ))
            t.kill

            results[:status].should  == :check_failed
            results[:message].should == framework.plugins[name]::STATUSES[:check_failed]
        end
    end
end
