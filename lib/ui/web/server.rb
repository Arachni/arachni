require 'sinatra/base'
require 'erb'


module Arachni
module UI

require Arachni::Options.instance.dir['lib'] + 'rpc/xml/output'
require Arachni::Options.instance.dir['lib'] + 'framework'

module Web

class Server < Sinatra::Base

    class OutputStream

        include Arachni::UI::Output

        def initialize( framework )
            @framework  = framework
        end

        def each
            flush_buffer.each {
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
    set :framework, Arachni::Framework.new( Arachni::Options.instance )
    enable :sessions

    def show( page, layout = true )
        begin
            erb page.to_sym
        rescue Exception => e
            erb :error, { :layout => false }, :error => e.to_s
        end
    end

    get "/" do
        show :home
    end

    post "/scan" do
        params.to_s
        settings.framework.opts.url = params['url']
        settings.framework.opts.link_count_limit = 1
        settings.framework.opts.audit_links = true
        settings.framework.modules.load( ['xss'] )
        settings.framework.run
        OutputStream.new( settings.framework )
    end

    run!
end

end
end
end
