require 'sinatra/base'
require "rack/csrf"
require 'rack-flash'
require 'erb'
require 'yaml'
require 'ap'


module Arachni
module UI

require Arachni::Options.instance.dir['lib'] + 'rpc/xml/client/dispatcher'
require Arachni::Options.instance.dir['lib'] + 'rpc/xml/client/instance'

module Web

class Server < Sinatra::Base

    class OutputStream

        def initialize( output )
            @output  = output
        end

        def each
            yield "<pre>"
            @output << { '' => '<meta http-equiv="refresh" content="1">' }
            @output.each {
                |out|
                yield "#{out.keys[0]}: #{out.values[0]}</br>"
            }
        end

    end

    use Rack::Flash

    configure do
        use Rack::Session::Cookie
        use Rack::Csrf, :raise => true
    end

    helpers do
        def csrf_token
            Rack::Csrf.csrf_token( env )
        end

        def csrf_tag
            Rack::Csrf.csrf_tag( env )
        end
    end

    dir = File.dirname( File.expand_path( __FILE__ ) )

    set :views,  "#{dir}/server/views"
    set :public, "#{dir}/server/public"
    set :static, true
    set :environment, :development

    set :dispatcher_url, 'http://localhost:7331'

    enable :sessions

    def exception_jail( &block )
        begin
            block.call
        rescue Exception => e
            erb :error, { :layout => false }, :error => e.to_s
        end
    end

    def show( page, layout = true )
        exception_jail {
            erb page.to_sym,  { :layout => layout }
        }
    end

    def connect_to_instance( port )
        uri = URI( settings.dispatcher_url )
        uri.port = port.to_i
        @instance ||= {}
        begin
            @instance[port] ||= Arachni::RPC::XML::Client::Instance.new( options, uri.to_s )
        rescue Exception
            raise "Instance on port #{port} has shutdown."
        end
    end

    def dispatcher
        @dispatcher ||= Arachni::RPC::XML::Client::Dispatcher.new( options, settings.dispatcher_url )
    end

    def options
        Arachni::Options.instance
    end

    def prep_opts( params )
        cparams = {}
        params.each_pair {
            |name, value|
            next if value.empty? || [ 'plugins', 'mods', '_csrf' ].include?( name )
            value = true if value == 'on'
            cparams[name] = value
        }
        return cparams
    end

    def prep_plugins( params )
        plugins  = {}

        return plugins if !params['plugins']
        params['plugins'].each {
            |name|
            plugins[name] = {}
        }
        ap plugins
        return plugins
    end

    get "/" do
        show :home
    end

    post "/scan" do
        instance = dispatcher.dispatch
        arachni  = connect_to_instance( instance['port'] )

        arachni.opts.set( prep_opts( params ) )

        if !params['mods']
            flash.now[:err] = "No modules have been selected."
            show :home
        elsif !params['audit_links'] && !params['audit_forms'] &&
              !params['audit_cookies'] && !params['audit_headers']
            flash.now[:err] = "No elements have been selected for audit."
            show :home
        else
            arachni.modules.load( params['mods'] )
            arachni.plugins.load( prep_plugins( params ) )
            arachni.framework.run

            redirect '/instance/' + instance['port'].to_s
        end
    end


    get "/instance/:port" do
        show :instance
    end

    get "/instance/:port/output" do
        exception_jail {
            arachni = connect_to_instance( params[:port] )

            if arachni.framework.busy?
                OutputStream.new( arachni.service.output )
            else
                report = YAML::load( arachni.framework.report )
                arachni.service.shutdown
                "<pre>" + report.to_s + "</pre>"
            end
        }
    end

    post "/instance/:port/pause" do
        exception_jail {
            connect_to_instance( params[:port] ).framework.pause!
            flash.now[:notice] = "Will pause as soon as the current page is audited."
            show :instance
        }
    end

    post "/instance/:port/resume" do
        exception_jail {
            connect_to_instance( params[:port] ).framework.resume!
            flash.now[:ok] = "Resuming..."
            show :instance
        }
    end

    post "/instance/:port/shutdown" do
        exception_jail {
            connect_to_instance( params[:port] ).framework.abort!
            connect_to_instance( params[:port] ).service.shutdown!
            flash.now[:ok] = "Instance on port #{params[:port]} has been shutdown."
            show :instance
        }
    end

    get "/stats" do
        dispatcher.stats.to_s
    end

    run!
end

end
end
end
