shared_examples_for "component" do

    before( :all ) do
        Arachni::Options.reset
        options.http.user_agent = 'arachni_user'

        @name = name
    end
    after( :all ) { framework.reset }

    def self.use_https
        # before( :all ) { options.url.gsub!( 'http', 'https' ) }
        @use_https = true
    end

    def name
        self.class.description
    end

    def component_name
        @name
    end

    def url
        @url ||= web_server_url_for( @use_https ? "#{name}_https" : name ) + '/'
    rescue
        raise "Could not find server for '#{name}' component."
    end

    def framework
        @f ||= Arachni::Framework.new
    end

    def reset_framework
        @f = nil
    end

    def session
        framework.session
    end

    def http
        framework.http
    end

    def options
        framework.options
    end

    def yaml_load( yaml )
        YAML.load yaml.gsub( '__URL__', url )
    end

    def run
        framework.run
    end
end
