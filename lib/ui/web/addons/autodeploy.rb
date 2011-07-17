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
# @version: 0.1
#
class AutoDeploy < Base

    def run

        settings.helpers do
            require File.dirname( __FILE__ ) + '/autodeploy/lib/manager'

            def autodeploy
                @@autodeploy ||= Manager.new( Options.instance, settings )
            end

        end

        get "/" do
            present :index, :deployments => autodeploy.list,
                :root => current_addon.path_root, :show_output => false,  :ret => {}

        end

        post "/" do

            if !params[:host] || params[:host].empty? || !params[:username] ||
                params[:username].empty? || !params[:password] || params[:password].empty? ||
                !params[:port] || params[:port].empty?

                flash[:err] = "Please fill in all the fields."

                present :index, :deployments => autodeploy.list,
                    :root => current_addon.path_root, :show_output => false,
                    :ret => {}
            else
                deployment = Manager::Deployment.new( :host => params[:host],
                    :port => params[:port], :user => params[:username] )

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

        get '/channel/:channel/finalize' do

            deployment = autodeploy.finalize_setup( params[:channel] )
            log.autodeploy_deployment_saved( env,
                "ID: #{deployment.id} - URL: #{autodeploy.get_url( deployment )}" )

            flash[:ok] = "Deployment was successful."

            present :index, :deployments => autodeploy.list, :ret => {},
                :root => current_addon.path_root, :show_output => false
        end


        post '/:id' do

            ret = {}
            if !params[:password] || params[:password].empty?
                flash[:err] = "The password field is required."
            else
                if params[:action] == 'delete'

                    ret = autodeploy.delete( params[:id], params[:password] )

                    if ret[:code]
                        flash[:err] = "Uninstall process aborted because the last command failed.<br/>" +
                            " Please ensure that the password is correct and the network is up."
                    else
                        log.autodeploy_deployment_deleted( env, params[:id] )
                        flash[:ok] = "Uninstall process was successful."
                    end

                elsif params[:action] == 'run'
                    deployment = autodeploy.get( params[:id] )
                    ret = autodeploy.run( deployment, params[:password] )

                    url = 'https://' + deployment.host + ':' + deployment.port

                    if settings.dispatchers.alive?( url )
                        flash[:ok] = "<br/>Dispatcher is up and running."
                        DispatcherManager::Dispatcher.first_or_create( :url => url )
                        settings.log.autodeploy_dispatcher_enabled( env,
                            "ID: #{deployment.id} - URL: #{autodeploy.get_url( deployment )}" )

                        ret = {}
                    else
                        flash[:err] = "Could not run the Dispatcher.<br/>" +
                            " Please ensure that the password is correct and the network is up."
                    end
                elsif params[:action] == 'shutdown'
                    deployment = autodeploy.get( params[:id] )
                    ret = autodeploy.shutdown( deployment, params[:password] )

                    if ret[:code] == 0 && !settings.dispatchers.alive?( url )
                        flash[:ok] = "<br/>Dispatcher has been shutdown."
                        settings.log.autodeploy_dispatcher_shutdown( env,
                            "ID: #{deployment.id} - URL: #{autodeploy.get_url( deployment )}" )

                        ret = {}
                    else
                        flash[:err] = "Could not shutdown the Dispatcher.<br/>" +
                            " Please ensure that the password is correct and the network is up."
                    end


                end
            end

            present :index, :deployments => autodeploy.list,
                :root => current_addon.path_root, :ret => ret, :show_output => false
        end


    end

    def title
        "Auto-deploy [#{Manager.new( Options.instance, settings ).list.size}]"
    end

    def self.info
        {
            :name           => 'Auto-deploy',
            :description    => %q{Allows you to automatically convert any SSH enabled Linux box into an Arachni Dispatcher.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1'
        }
    end


end

end
end
end
end
