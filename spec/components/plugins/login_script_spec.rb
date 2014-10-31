require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.url = url
    end

    before :each do
        options.session.check_url     = nil
        options.session.check_pattern = nil

        IO.write( script_path, script )

        options.plugins[component_name] = { 'script' => script_path }
    end

    after(:each) { FileUtils.rm_f script_path }

    let(:script) { '' }
    let(:script_path) { "#{Dir.tmpdir}/login_script_#{Time.now.to_i}" }

    context 'when a browser' do
        let(:script) do
            <<EOSCRIPT
                framework.options.datastore.browser = browser
EOSCRIPT
        end

        context 'is available' do
            it "exposes a Watir::Browser interface via the 'browser' variable" do
                run

                options.datastore.browser.should be_kind_of Watir::Browser
            end
        end

        context 'is not available' do
            it "sets 'browser' to 'nil'" do
                framework.options.scope.dom_depth_limit = 0
                run

                options.datastore.browser.should be_nil
            end
        end
    end

    context 'when the login was successful' do
        before :each do
            options.session.check_url     = url
            options.session.check_pattern = 'Hi there logged-in user'
        end

        let(:script) do
            <<EOSCRIPT
                http.cookie_jar.update 'success' => 'true'
EOSCRIPT
        end

        it 'sets the status' do
            run

            actual_results['status'].should  == 'success'
        end

        it 'sets the message' do
            run

            actual_results['message'].should == plugin::STATUSES[:success]
        end

        it 'sets the cookies' do
            run

            actual_results['cookies'].should == { 'success' => 'true' }
        end
    end

    context 'when there is no session check' do
        let(:script) do
            <<EOSCRIPT
                http.cookie_jar.update 'success' => 'true'
EOSCRIPT
        end

        it 'sets the status' do
            run

            actual_results['status'].should  == 'missing_check'
        end

        it 'sets the message' do
            run

            actual_results['message'].should == plugin::STATUSES[:missing_check]
        end

        it 'aborts the scan' do
            run

            framework.status.should == :aborted
        end
    end

    context 'when the session check fails' do
        before :each do
            options.session.check_url     = url
            options.session.check_pattern = 'Hi there logged-in user'
        end

        it 'sets the status' do
            run

            actual_results['status'].should  == 'failure'
        end

        it 'sets the message' do
            run

            actual_results['message'].should == plugin::STATUSES[:failure]
        end

        it 'aborts the scan' do
            run

            framework.status.should == :aborted
        end
    end

    context 'when there is a runtime error in the script' do
        let(:script) do
            <<EOSCRIPT
                fail
EOSCRIPT
        end

        it 'sets the status' do
            run

            actual_results['status'].should  == 'error'
        end

        it 'sets the message' do
            run

            actual_results['message'].should == plugin::STATUSES[:error]
        end

        it 'aborts the scan' do
            run

            framework.status.should == :aborted
        end
    end

end
