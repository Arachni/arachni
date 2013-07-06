shared_examples_for "component" do

    before( :all ) do
        Arachni::Options.reset
        options.user_agent = 'arachni_user'
    end
    after( :all ) { framework.reset }

    def self.use_https
        before( :all ) { options.url.gsub!( 'http', 'https' ) }
    end

    def name
        self.class.description
    end

    def url
        @url ||= web_server_url_for( name ) + '/'
    rescue
        raise "Could not find server for '#{name}' component."
    end

    def framework
        @f ||= Arachni::Framework.new
    end

    def session
        framework.session
    end

    def http
        framework.http
    end

    def options
        framework.opts
    end

    def yaml_load( yaml )
        YAML.load yaml.gsub( '__URL__', url )
    end

    def run
        framework.run
    end
end
