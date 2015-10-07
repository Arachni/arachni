shared_examples_for 'wavsep' do

    let(:wavsep_url) { ENV['WAVSEP_URL'] }
    let(:url) { "#{wavsep_url}/active/" }

    before :each do
        Arachni::Options.reset

        @framework = Arachni::Framework.new
        @framework.options.audit.elements :links, :forms
    end

    after :each do
        @framework.reset
        process_kill_reactor
    end

    def format_error( logged_urls, logged_resources, expected_resources )
        error = "Logged URLs:\n"
        logged_urls.each_with_index do |url, idx|
            error << "    [#{idx}] #{url}\n"
        end
        error << "\n"

        error << "Logged resources:\n"
        logged_resources.each_with_index do |url, idx|
            error << "    [#{idx}] #{url}\n"
        end
        error << "\n"

        error << "Expected resources:\n"
        expected_resources.each_with_index do |url, idx|
            error << "    [#{idx}] #{url}\n"
        end
        error << "\n"

        error << "Missed resources:\n"
        (expected_resources - logged_resources).each_with_index do |url, idx|
            error << "    [#{idx}] #{url}\n"
        end
        error << "\n"

        error << "Extra resources:\n"
        (logged_resources - expected_resources).each_with_index do |url, idx|
            error << "    [#{idx}] #{url}\n"
        end
        error << "\n"
    end

    def test_cases( http_method )
        {
            'Description' => {
                url:        'URL to audit',
                checks:     'checks to load',
                vulnerable: [ 'Vulnerable URLs' ]
            }
        }
    end

    def self.methods
        ['GET', 'POST']
    end

    def self.easy_test( &block )
        methods.each do |http_method|
            context 'when the vectors use' do
                context http_method do
                    context 'and the webapp returns' do
                        test_cases( http_method ).each do |description, info|
                            context description do
                                it "logs #{(info[:vulnerable] || []).size + (info[:vulnerable_absolute] || []).size} unique resources using #{[info[:checks]].flatten.join( ', ' )}" do
                                    skip "'WAVSEP_URL' env variable has not been set." if !wavsep_url

                                    expect(Arachni::Data.issues).to be_empty

                                    if info[:root_url]
                                        @framework.options.url = wavsep_url
                                    else

                                        @framework.options.url = "#{url}/#{info[:url]}"
                                    end

                                    @framework.checks.load info[:checks]
                                    @framework.run

                                    urls      = Arachni::Data.issues.map { |i| i.vector.action }.uniq.sort
                                    resources = urls.map { |url| url.split('?').first }.uniq.sort
                                    expected  = info[:vulnerable].map { |resource| @framework.options.url + resource }

                                    if info[:vulnerable_absolute]
                                        expected |= info[:vulnerable_absolute].map { |resource| wavsep_url + resource }
                                    end

                                    expected.sort!

                                    # pp resources.map { |u| u.gsub( @framework.options.url, '' ) }
                                    # puts format_error( urls, resources, expected )

                                    expect(resources).to eq(expected), format_error( urls, resources, expected )

                                    instance_eval &block if block_given?
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
