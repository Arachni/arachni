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
                'parameters' => 'username=john&password=doe&submit_me=submitted',
                'check'      => 'Hi there logged-in user'
            }

            run

            expect(actual_results['status']).to  eq('ok')
            expect(actual_results['message']).to eq(plugin::STATUSES[:ok])
            expect(actual_results['cookies']['success']).to eq('true')

            expect(framework.sitemap.include?( url + 'congrats' )).to be_truthy
        end

        it 'provides a login sequence and login check to the framework' do
            options.plugins[component_name] = {
                'url'        => url + '/login',
                'parameters' => 'username=john&password=doe&submit_me=submitted',
                'check'      => 'Hi there logged-in user'
            }

            # The framework will call #clean_up which nil out the session...
            session = framework.session
            # ...in addition to removing its configuration.
            allow(session).to receive(:clean_up)

            run

            expect(session.logged_in?).to be_truthy

            http.cookie_jar.clear

            expect(session.logged_in?).to be_falsey
            expect(session.login).to be_truthy
            expect(session.logged_in?).to be_truthy
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

            expect(actual_results['status']).to  eq('form_not_found')
            expect(actual_results['message']).to eq(plugin::STATUSES[:form_not_found])
        end

        it 'aborts the scan' do
            run

            expect(framework.status).to eq(:aborted)
        end
    end

    context 'when the form is not visible' do
        before do
            options.plugins[component_name] = {
                'url'        => url + '/hidden_login',
                'parameters' => 'username=john&password=doe',
                'check'      => 'Hi there logged-in user'
            }
        end

        it 'complains about not the form being invisible' do
            run

            expect(actual_results['status']).to  eq('form_not_visible')
            expect(actual_results['message']).to eq(plugin::STATUSES[:form_not_visible])
        end

        it 'aborts the scan' do
            run

            expect(framework.status).to eq(:aborted)
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

            expect(actual_results['status']).to  eq('check_failed')
            expect(actual_results['message']).to eq(plugin::STATUSES[:check_failed])
        end

        it 'aborts the scan' do
            run

            expect(framework.status).to eq(:aborted)
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
                expect(framework.options.session.check_url).to eq(url)
            end
        end

        context 'is set' do
            it 'does not change it' do
                option_url = url + '/stuff'
                framework.options.session.check_url = option_url
                run
                expect(framework.options.session.check_url).to eq(option_url)
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
                expect(framework.options.session.check_pattern).to eq(/Hi there logged-in user/)
            end
        end

        context 'is set' do
            it 'does not change it' do
                framework.options.session.check_pattern = /stuff/
                run
                expect(framework.options.session.check_pattern).to eq(/stuff/)
            end
        end
    end

end
