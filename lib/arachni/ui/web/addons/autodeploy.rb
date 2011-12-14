=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module UI
module Web
module Addons

#
#
# Auto-deploy add-on.
#
# Allows users to automatically convert any SSH enabled Linux box into an Arachni Dispatcher.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
#
# @version: 0.1.1
#
class AutoDeploy < Base

    def run

        settings.helpers do
            require File.dirname( __FILE__ ) + '/autodeploy/lib/manager'

            def autodeploy
                @@autodeploy ||= Manager.new( Options.instance, settings )
            end

        end

        aget "/" do
            autodeploy.list_with_liveness {
                |deployments|
                async_present :index, :deployments => deployments,
                    :root => current_addon.path_root, :show_output => false,
                    :ret => {}
            }
        end

        post "/" do

            opts = {}
            if !params[:pool_size].empty?
                opts[:pool_size] = params[:pool_size].to_i
            end

            if !params[:nickname].empty?
                opts[:nickname]  = params[:nickname]
            end

            if !params[:weight].empty?
                opts[:weight]    = params[:weight]
            end

            if params[:pipe_id].empty?
                opts[:pipe_id]   = params[:pipe_id]
            end

            params.each { |k, v| opts[k.to_sym] = v }
            opts.delete( :password )
            opts.delete( :_csrf )

            deployment = Manager::Deployment.new( opts )

            if !params[:host] || params[:host].empty? || !params[:username] ||
                params[:username].empty? || !params[:password] || params[:password].empty? ||
                !params[:port] || params[:port].empty? ||
                !params[:dispatcher_port] || params[:dispatcher_port].empty?

                flash[:err] = "Please fill in all mandatory fields."

                present :index, :deployments => autodeploy.list,
                    :root => current_addon.path_root, :show_output => false,
                    :ret => {}, :errors => deployment.errors
            else

                settings.log.autodeploy_setup_started( env, autodeploy.get_url( deployment ) )
                channel = autodeploy.setup( deployment, params[:password] )

                present :index, :deployments => autodeploy.list,
                    :root => current_addon.path_root, :channel => channel,
                    :show_output => true,  :ret => {}
            end
        end

        get '/channel/:channel' do
            content_type :json
            autodeploy.output( params[:channel] ).to_json
        end

        get '/channel/:channel/finalize' do |channel|
            deployment = autodeploy.finalize_setup( params[:channel] )
            log.autodeploy_deployment_saved( env,
                "ID: #{deployment.id} [#{autodeploy.get_url( deployment )}]" )

            redirect '/', :flash => { :ok => "Deployment was successful." }
        end

        apost '/:id' do |id|

            ret = {}
            if !params[:password] || params[:password].empty?
                msg = "The password field is required."
                async_redirect '/', :flash => { :err => msg }
            else
                if params[:action] == 'delete'

                    ret = autodeploy.delete( params[:id], params[:password] )

                    if ret[:code]
                        msg = "Uninstall process aborted because the last command failed." +
                            " Please ensure that the password is correct and the network is up."
                        async_redirect '/', :flash => { :err => msg }
                    else
                        log.autodeploy_deployment_deleted( env, params[:id] )
                        msg = "Uninstall process was successful."
                        async_redirect '/', :flash => { :ok => msg }
                    end

                elsif params[:action] == 'run'
                    deployment = autodeploy.get( params[:id] )
                    ret = autodeploy.run( deployment, params[:password] )

                    autodeploy.alive?( deployment ){
                        |alive|

                        if alive
                            msg = "Dispatcher is up and running."

                            url = deployment.host + ':' + deployment.dispatcher_port.to_s
                            DispatcherManager::Dispatcher.first_or_create( :url => url )

                            settings.log.autodeploy_dispatcher_enabled( env,
                                "ID: #{deployment.id} [#{autodeploy.get_url( deployment )}]" )

                            async_redirect '/', :flash => { :ok => msg }
                        else
                            msg = "Could not run the Dispatcher." +
                                " Please ensure that the password is correct and the network is up."

                            async_redirect '/', :flash => { :err => msg }
                        end
                    }
                elsif params[:action] == 'shutdown'
                    deployment = autodeploy.get( params[:id] )
                    autodeploy.shutdown( deployment, params[:password] ) {
                        |ret|
                        err = "Could not shutdown the Dispatcher." +
                            " Please ensure that the password is correct and the network is up."

                        if ret[:code] == 0
                           autodeploy.alive?( deployment ){
                               |liveness|
                               if !liveness
                                   msg = "Dispatcher has been shutdown."

                                   settings.log.autodeploy_dispatcher_shutdown( env,
                                        "ID: #{deployment.id} [#{autodeploy.get_url( deployment )}]" )

                                   async_redirect '/', :flash => { :ok => msg }
                               else
                                   async_redirect '/', :flash => { :err => err }
                               end
                           }
                        else
                            async_redirect '/', :flash => { :err => err }
                    end
                    }
                end
            end

        end


    end

    def title
        "Auto-deploy [#{Manager.new( Options.instance, settings ).list.size}]"
    end

    def self.info
        {
            :name           => 'Auto-deploy',
            :description    => %q{Enables you to automatically convert any SSH enabled Linux box into an Arachni Dispatcher.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1.1'
        }
    end


end

end
end
end
end
