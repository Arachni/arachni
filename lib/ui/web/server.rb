require 'sinatra/base'
require 'erb'
require 'yaml'


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
            @output << { '' => '<meta http-equiv="refresh" content="1"> ' }
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
    enable :sessions

    def show( page, layout = true )
        begin
            erb page.to_sym
        rescue Exception => e
            erb :error, { :layout => false }, :error => e.to_s
        end
    end

    def arachni_from_session
        Arachni::RPC::XML::Client::Instance.new( Arachni::Options.instance, session['url'] )
    end

    get "/" do
        show :home
    end

    post "/scan" do
         dispatcher = Arachni::RPC::XML::Client::Dispatcher.new( Arachni::Options.instance, 'http://localhost:7331' )

        instance = dispatcher.dispatch
        session['url'] = "http://localhost:" + instance['port'].to_s

        arachni = arachni_from_session( )

        arachni.opts.url( params['url'] )
        arachni.opts.link_count_limit( 1 )
        arachni.opts.audit_links( true )
        arachni.opts.audit_forms( true )
        arachni.opts.audit_cookies( true )
        arachni.modules.load( ['*'] )
        arachni.framework.run

        redirect '/output'
    end

    get "/output" do
        arachni = arachni_from_session( )
        if arachni.framework.busy?
            OutputStream.new( arachni.service.output )
        else
            "<pre>" + YAML::load( arachni.framework.report ).to_s + "</pre>"
        end
    end


    run!
end

end
end
end
