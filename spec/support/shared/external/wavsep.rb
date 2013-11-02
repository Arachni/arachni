shared_examples_for 'wavsep' do

    let(:base_url) { "#{ENV['WAVSEP_URL']}/" }
    let(:url) { "#{base_url}active/" }

    before :each do
        Arachni::Options.reset

        @framework = Arachni::Framework.new
        @framework.opts.audit :links, :forms

        # WAVSEP chokes easily.
        @framework.opts.http_req_limit = 1
    end

    after :each do
        @framework.reset
        @framework = Arachni::Framework.new
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
    end

    def test_cases( http_method )
        {
            'Description' => {
                url:        'URL to audit',
                modules:    'modules to load',
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
                                it "logs #{info[:vulnerable].size} unique resources using #{[info[:modules]].flatten.join( ', ' )}" do
                                    pending "No 'WAVSEP_URL' env variable has been set." if !ENV['WAVSEP_URL']

                                    @framework.opts.url = "#{url}/#{info[:url]}"
                                    @framework.modules.load info[:modules]
                                    @framework.run

                                    urls      = @framework.modules.issues.map(&:url).uniq.sort
                                    resources = urls.map { |url| url.split('?').first }.uniq.sort
                                    expected  = info[:vulnerable].map { |resource| @framework.opts.url + resource }

                                    resources.should eq(expected), format_error( urls, resources, expected )

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
