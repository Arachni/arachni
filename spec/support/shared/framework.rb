shared_examples_for 'framework' do

    before( :all ) do
        @url   = web_server_url_for( :auditor )
        @f_url = web_server_url_for( :framework )

        @options = Arachni::Options.instance
    end

    before( :each ) do
        reset_options
        @options.paths.reporters = fixtures_path + '/reporters/manager_spec/'
        @options.paths.checks    = fixtures_path + '/signature_check/'

        @f = Arachni::Framework.new
        @f.options.url = @url
    end
    after( :each ) do
        File.delete( @snapshot ) rescue nil

        @f.clean_up
        @f.reset
    end

    subject { @f }
end
