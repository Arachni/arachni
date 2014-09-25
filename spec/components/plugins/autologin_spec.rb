require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.url = url
    end

    before :each do
        options.session.check_url     = nil
        options.session.check_pattern = nil
    end

    context 'when given the right params' do
        it 'locates the form and login successfully' do
            options.plugins[component_name] = {
                'url'        => url + '/login',
                'parameters' => 'username=john&password=doe',
                'check'      => 'Hi there logged-in user'
            }

            run

            actual_results['status'].should  == 'ok'
            actual_results['message'].should == plugin::STATUSES[:ok]
            actual_results['cookies']['success'].should == 'true'

            framework.sitemap.include?( url + 'congrats' ).should be_true
        end

        it 'provides a login sequence and login check to the framework' do
            options.plugins[component_name] = {
                'url'        => url + '/login',
                'parameters' => 'username=john&password=doe',
                'check'      => 'Hi there logged-in user'
            }

            # The framework will call #clean_up which nil out the session...
            session = framework.session
            # ...in addition to removing its configuration.
            session.stub(:clean_up)

            run

            session.logged_in?.should be_true

            http.cookie_jar.clear

            session.logged_in?.should be_false
            session.login.should be_true
            session.logged_in?.should be_true
        end
    end

    context 'when given invalid params' do
        before do
            options.plugins[component_name] = {
                'url'        => url + '/login',
                'parameters' => 'username2=john&password=doe',
                'check'      => 'Hi there logged-in user'
            }
        end

        it 'complains about not being able to find the form' do
            run

            actual_results['status'].should  == 'form_not_found'
            actual_results['message'].should == plugin::STATUSES[:form_not_found]
        end

        it 'aborts the scan' do
            run

            framework.status.should == :aborted
        end
    end

    context 'when the verifier does not match' do
        before do
            options.plugins[component_name] = {
                'url'        => url + '/login',
                'parameters' => 'username=john&password=doe',
                'check'      => 'Hi there Jimbo'
            }
        end

        it 'complains about not being able to verify the login' do
            run

            actual_results['status'].should  == 'check_failed'
            actual_results['message'].should == plugin::STATUSES[:check_failed]
        end

        it 'aborts the scan' do
            run

            framework.status.should == :aborted
        end
    end

    context "when #{Arachni::OptionGroups::Session}#check_url is" do
        before do
            options.plugins[component_name] = {
                'url'        => url + '/login',
                'parameters' => 'username=john&password=doe',
                'check'      => 'Hi there logged-in user'
            }
        end

        context 'nil' do
            it 'sets it to the login response URL' do
                framework.options.session.check_url = nil
                run
                framework.options.session.check_url.should == url
            end
        end

        context 'is set' do
            it 'does not change it' do
                option_url = url + '/stuff'
                framework.options.session.check_url = option_url
                run
                framework.options.session.check_url.should == option_url
            end
        end
    end

    context "when #{Arachni::OptionGroups::Session}#check_pattern is" do
        before do
            options.plugins[component_name] = {
                'url'        => url + '/login',
                'parameters' => 'username=john&password=doe',
                'check'      => 'Hi there logged-in user'
            }
        end

        context 'nil' do
            it 'sets it to the plugin pattern' do
                framework.options.session.check_pattern = nil
                run
                framework.options.session.check_pattern.should == /Hi there logged-in user/
            end
        end

        context 'is set' do
            it 'does not change it' do
                framework.options.session.check_pattern = /stuff/
                run
                framework.options.session.check_pattern.should == /stuff/
            end
        end
    end

end
