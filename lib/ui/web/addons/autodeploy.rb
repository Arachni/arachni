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
            ret = {}
            present :index, :deployments => autodeploy.list,
                :root => current_addon.path_root, :ret => ret

        end

        post "/" do

            ret = {}
            if !params[:host] || params[:host].empty? || !params[:username] ||
                params[:username].empty? || !params[:password] || params[:password].empty? ||
                !params[:port] || params[:port].empty?

                flash[:err] = "Please fill in all the fields."
            else
                deployment = Manager::Deployment.new( :host => params[:host],
                    :port => params[:port], :user => params[:username] )

                ret = autodeploy.setup( deployment, params[:password] )

                if ret[:code]
                    flash[:err] = "Setup was aborted because the last command failed."
                else
                    deployment.save
                    log.autodeploy_deployment_saved( env, deployment.id )
                    flash[:ok] = "Deployment was successful."

                    if params[:run]
                        autodeploy.run( deployment, params[:password] )

                        url = 'https://' + deployment.host + ':' + deployment.port

                        if settings.dispatchers.alive?( url )
                            flash[:ok] += "<br/>Dispatcher is up and running."
                            DispatcherManager::Dispatcher.first_or_create( :url => url )
                        else
                            flash[:err] = "Could not run the Dispatcher."
                        end
                    end

                end

            end

            present :index, :deployments => autodeploy.list,
                :root => current_addon.path_root, :ret => ret
        end

        post '/:id' do
            ret = {}

            if !params[:password] || params[:password].empty?
                flash[:err] = "The password field is required."
            else
                if params[:action] == 'delete'

                    ret = autodeploy.delete( params[:id], params[:password] )

                    if ret[:code]
                        flash[:err] = "Uninstall process aborted because the last command failed."
                    else
                        log.autodeploy_deployment_deleted( env, params[:id] )
                        flash[:ok] = "Uninstall process was successful."
                    end

                elsif params[:action] == 'run'
                    deployment = autodeploy.get( params[:id] )
                    autodeploy.run( deployment, params[:password] )

                    url = 'https://' + deployment.host + ':' + deployment.port

                    if settings.dispatchers.alive?( url )
                        flash[:ok] = "<br/>Dispatcher is up and running."
                        DispatcherManager::Dispatcher.first_or_create( :url => url )
                    else
                        flash[:err] = "Could not run the Dispatcher."
                    end
                end
            end

            present :index, :deployments => autodeploy.list,
                :root => current_addon.path_root, :ret => ret
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
