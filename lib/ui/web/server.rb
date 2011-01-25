require 'sinatra/base'
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
            erb page.to_sym
        }
    end

    def connect_to_instance( port )
        exception_jail {
            uri = URI( settings.dispatcher_url )
            uri.port = port.to_i
            @instance ||= {}
            @instance[port] ||= Arachni::RPC::XML::Client::Instance.new( options, uri.to_s )
        }
    end

    def dispatcher
        @dispatcher ||= Arachni::RPC::XML::Client::Dispatcher.new( options, settings.dispatcher_url )
    end

    def options
        Arachni::Options.instance
    end

    get "/" do
        show :home
    end

    post "/scan" do
        instance = dispatcher.dispatch
        arachni = connect_to_instance( instance['port'] )

        arachni.opts.url( params['url'] )
        arachni.opts.link_count_limit( 1 )
        arachni.opts.audit_links( true )
        arachni.opts.audit_forms( true )
        arachni.opts.audit_cookies( true )
        arachni.modules.load( ['*'] )
        arachni.framework.run

        redirect '/instance/' + instance['port'].to_s
    end

    get "/instance/:port" do
        arachni = connect_to_instance( params[:port] )
        if arachni.framework.busy?
            OutputStream.new( arachni.service.output )
        else
            report = YAML::load( arachni.framework.report )
            arachni.service.shutdown
            "<pre>" + report.to_s + "</pre>"
        end
    end

    put "/instance/:port/pause"
        exception_jail {
            connect_to_instance( params[:port] ).framework.pause!
        }
    end

    put "/instance/:port/resume"
        exception_jail {
            connect_to_instance( params[:port] ).framework.resume!
        }
    end

    delete "/instance/:port"
        exception_jail {
            connect_to_instance( params[:port] ).framework.abort!
            connect_to_instance( params[:port] ).service.shutdown!
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
