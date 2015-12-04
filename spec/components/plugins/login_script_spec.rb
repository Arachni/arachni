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

        framework.options.scope.dom_depth_limit = 1
    end

    after(:each) { FileUtils.rm_f script_path }

    let(:script) { '' }
    let(:script_path) { "#{Dir.tmpdir}/login_script_#{Time.now.to_i}" }

    context 'when a browser' do
        context 'is available' do
            context 'when using a Ruby script' do
                let(:script) do
                    <<EOSCRIPT
                framework.options.datastore.browser = browser.class.to_s
                framework.options.datastore.screen_width = browser.execute_script( 'return window.innerWidth;' )
                framework.options.datastore.screen_height = browser.execute_script( 'return window.innerHeight;' )
EOSCRIPT
                end

                it "exposes a Watir::Browser interface via the 'browser' variable" do
                    run

                    expect(options.datastore.browser).to eq 'Watir::Browser'
                end

                it 'sets the appropriate resolution' do
                    run

                    expect(framework.options.datastore.screen_width).to eq Arachni::Options.browser_cluster.screen_width
                    expect(framework.options.datastore.screen_height).to eq Arachni::Options.browser_cluster.screen_height
                end
            end

            context 'when using a Javascript script' do
                let(:script) do
                    <<EOSCRIPT
                document.cookie = 'mycookie=myvalue'
                document.cookie = 'width=' + window.innerWidth
                document.cookie = 'height=' + window.innerHeight
EOSCRIPT
                end
                let(:script_path) { "#{super()}.js" }

                it 'runs the code' do
                    run

                    expect(framework.http.cookies.
                        find { |c| c.name == 'mycookie' }.value).to eq('myvalue')
                end

                it 'sets the appropriate resolution' do
                    run

                    expect(framework.http.cookies.
                        find { |c| c.name == 'width' }.value).to eq Arachni::Options.browser_cluster.screen_width.to_s
                    expect(framework.http.cookies.
                        find { |c| c.name == 'height' }.value).to eq Arachni::Options.browser_cluster.screen_height.to_s
                end
            end
        end

        context 'is not available' do
            before do
                framework.options.scope.dom_depth_limit = 0
            end

            context 'when using a Ruby script' do
                let(:script) do
                    <<EOSCRIPT
                    framework.options.datastore.browser = browser
EOSCRIPT
                end

                it "sets 'browser' to 'nil'" do
                    run

                    expect(options.datastore.browser).to be_nil
                end
            end

            context 'when using a Javascript script' do
                let(:script) do
                    <<EOSCRIPT
                document.cookie = 'mycookie=myvalue'
EOSCRIPT
                end
                let(:script_path) { "#{super()}.js" }

                it 'sets the status' do
                    run

                    expect(actual_results['status']).to  eq('missing_browser')
                end

                it 'sets the message' do
                    run

                    expect(actual_results['message']).to eq(plugin::STATUSES[:missing_browser])
                end

                it 'aborts the scan' do
                    run

                    expect(framework.status).to eq(:aborted)
                end
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

            expect(actual_results['status']).to  eq('success')
        end

        it 'sets the message' do
            run

            expect(actual_results['message']).to eq(plugin::STATUSES[:success])
        end

        it 'sets the cookies' do
            run

            expect(actual_results['cookies']).to eq({ 'success' => 'true' })
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

            expect(actual_results['status']).to  eq('missing_check')
        end

        it 'sets the message' do
            run

            expect(actual_results['message']).to eq(plugin::STATUSES[:missing_check])
        end

        it 'aborts the scan' do
            run

            expect(framework.status).to eq(:aborted)
        end
    end

    context 'when the session check fails' do
        before :each do
            options.session.check_url     = url
            options.session.check_pattern = 'Hi there logged-in user'
        end

        it 'sets the status' do
            run

            expect(actual_results['status']).to  eq('failure')
        end

        it 'sets the message' do
            run

            expect(actual_results['message']).to eq(plugin::STATUSES[:failure])
        end

        it 'aborts the scan' do
            run

            expect(framework.status).to eq(:aborted)
        end
    end

    context 'when there is a runtime error in the script' do
        context 'when using Ruby' do
            let(:script) do
                <<EOSCRIPT
                    fail
EOSCRIPT
            end

            it 'sets the status' do
                run

                expect(actual_results['status']).to  eq('error')
            end

            it 'sets the message' do
                run

                expect(actual_results['message']).to eq(plugin::STATUSES[:error])
            end

            it 'aborts the scan' do
                run

                expect(framework.status).to eq(:aborted)
            end
        end

        context 'when using Javascript' do
            let(:script) do
                <<EOSCRIPT
                doesNotExist()
EOSCRIPT
            end
            let(:script_path) { "#{super()}.js" }

            it 'sets the status' do
                run

                expect(actual_results['status']).to  eq('error')
            end

            it 'sets the message' do
                run

                expect(actual_results['message']).to eq(plugin::STATUSES[:error])
            end

            it 'aborts the scan' do
                run

                expect(framework.status).to eq(:aborted)
            end
        end
    end

    context 'when there is a syntax error in the script' do
        context 'when using Ruby' do
            let(:script) do
                <<EOSCRIPT
                    {
                        id: => stuff
                    }
EOSCRIPT
            end

            it 'sets the status' do
                run

                expect(actual_results['status']).to  eq('error')
            end

            it 'sets the message' do
                run

                expect(actual_results['message']).to eq(plugin::STATUSES[:error])
            end

            it 'aborts the scan' do
                run

                expect(framework.status).to eq(:aborted)
            end
        end

        context 'when using Javascript' do
            let(:script) do
                <<EOSCRIPT
                document.cookie = '
EOSCRIPT
            end
            let(:script_path) { "#{super()}.js" }

            it 'sets the status' do
                run

                expect(actual_results['status']).to  eq('error')
            end

            it 'sets the message' do
                run

                expect(actual_results['message']).to eq(plugin::STATUSES[:error])
            end

            it 'aborts the scan' do
                run

                expect(framework.status).to eq(:aborted)
            end
        end
    end

end
