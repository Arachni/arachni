require 'spec_helper'

describe Arachni::Framework do
    include_examples 'framework'

    describe '#initialize' do
        context 'when passed a block' do
            it 'executes it' do
                ran = false
                Arachni::Framework.new do |f|
                    ran = true
                end

                expect(ran).to be_truthy
            end

            it 'resets the framework' do
                expect(Arachni::Checks.constants.include?( :Signature )).to be_falsey

                Arachni::Framework.new do |f|
                    expect(f.checks.load_all).to eq(%w(signature))
                    expect(Arachni::Checks.constants.include?( :Signature )).to be_truthy
                end

                expect(Arachni::Checks.constants.include?( :Signature )).to be_falsey
            end

            context 'when an exception is raised' do
                it 'raises it' do
                    expect { Arachni::Framework.new { |f| raise } }.to raise_error
                end
            end
        end
    end

    describe '#version' do
        it "returns #{Arachni::VERSION}" do
            expect(subject.version).to eq(Arachni::VERSION)
        end
    end

    describe '#options' do
        it "provides access to #{Arachni::Options}" do
            expect(subject.options).to be_kind_of Arachni::Options
        end
    end

    describe '#run' do
        it 'follows redirects' do
            subject.options.url = @f_url + '/redirect'
            subject.run
            expect(subject.sitemap).to eq({
                "#{@f_url}/redirect"   => 302,
                "#{@f_url}/redirected" => 200
            })
        end

        it 'performs the scan' do
            subject.options.url = @url + '/elem_combo'
            subject.options.audit.elements :links, :forms, :cookies
            subject.checks.load :signature
            subject.plugins.load :wait

            subject.run
            expect(subject.report.issues.size).to eq(3)

            expect(subject.report.plugins[:wait][:results]).to eq({ 'stuff' => true })
        end

        it 'sets #status to scanning' do
            described_class.new do |f|
                f.options.url = @url + '/elem_combo'
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :signature

                t = Thread.new { f.run }
                Timeout.timeout( 5 ) do
                    sleep 0.1 while f.status != :scanning
                end
                t.join
            end
        end

        it 'handles heavy load' do
            @options.paths.checks = fixtures_path + '/signature_check/'

            Arachni::Framework.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.checks.load :signature

                f.run
                expect(f.report.issues.size).to eq(500)
            end
        end

        it 'handles pages with JavaScript code' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/with_javascript'
                f.options.audit.elements :links, :forms, :cookies

                f.checks.load :signature
                f.run

                expect(
                    f.report.issues.
                        map { |i| i.vector.affected_input_name }.
                        uniq.sort
                ).to eq(%w(link_input form_input cookie_input).sort)
            end
        end

        it 'handles AJAX' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/with_ajax'
                f.options.audit.elements :links, :forms, :cookies

                f.checks.load :signature
                f.run

                expect(
                    f.report.issues.
                        map { |i| i.vector.affected_input_name }.
                        uniq.sort
                ).to eq(%w(link_input form_input cookie_taint).sort)
            end
        end

        context 'when done' do
            it 'sets #status to :done' do
                described_class.new do |f|
                    f.options.url = @url + '/elem_combo'
                    f.options.audit.elements :links, :forms, :cookies
                    f.checks.load :signature

                    f.run
                    expect(f.status).to eq(:done)
                end
            end
        end

        context 'when it has log-in capabilities and gets logged out' do
            it 'logs-in again before continuing with the audit' do
                Arachni::Framework.new do |f|
                    url = web_server_url_for( :framework ) + '/'
                    f.options.url = "#{url}/congrats"

                    f.options.audit.elements :links, :forms
                    f.checks.load_all

                    f.session.configure(
                        url:    url,
                        inputs: {
                            username: 'john',
                            password: 'doe'
                        }
                    )

                    f.options.session.check_url     = url
                    f.options.session.check_pattern = 'logged-in user'

                    f.run
                    expect(f.report.issues.size).to eq(1)
                end
            end
        end
    end

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        it 'includes http statistics' do
            expect(statistics[:http]).to eq(subject.http.statistics)
        end

        it 'includes browser cluster statistics' do
            expect(statistics[:browser_cluster]).to eq(Arachni::BrowserCluster.statistics)
        end

        [:found_pages, :audited_pages, :current_page].each  do |k|
            it "includes #{k}" do
                expect(statistics).to include k
            end
        end

        describe ':runtime' do
            context 'when the scan has been running' do
                it 'returns the runtime in seconds' do
                    subject.run
                    expect(statistics[:runtime]).to be > 0
                end
            end

            context 'when no scan has been running' do
                it 'returns 0' do
                    expect(statistics[:runtime]).to eq(0)
                end
            end
        end
    end

end
