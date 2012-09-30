=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

require Arachni::Options.instance.dir['lib'] + 'rpc/client/dispatcher'
require Arachni::Options.instance.dir['lib'] + 'ui/web/utilities'

module Arachni
module UI
module Web

#
# Schedules and executes scan jobs.
#
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.1.2
#
class Scheduler

    include Utilities

    class Job
        include DataMapper::Resource

        property :id,           Serial
        property :dispatcher,   String
        property :url,          String
        property :opts,         Text
        property :datetime,     DateTime

        property :owner_addr,   String
        property :owner_host,   String

        property :created_at,   DateTime
    end

    #
    # Initializes the Scheduler and starts the clock.
    #
    #
    def initialize( opts, settings )
        @opts     = opts
        @settings = settings

        DataMapper::setup( :default, "sqlite3://#{@settings.db}/default.db" )
        DataMapper.finalize

        Job.auto_upgrade!

        ticktock!
    end

    #
    # Runs a job.
    #
    # @param    [Job]   job
    # @param    [Hash]  env  Sinatra environment
    # @param    [Hash]  session  Rack session
    #
    # @return   [String]    URL of the laucnhed scanner instance
    #
    def run( job, env = nil, session = nil, &block )
        raise( "This method requires a block!" ) if !block_given?

        @settings.dispatchers.connect( job.dispatcher ).dispatch( job.url ){
            |instance|

            if instance.rpc_exception?
                @settings.log.scheduler_instance_dispatch_failed( env )
                next
            end

            env = {
                'REMOTE_ADDR' => job.owner_addr,
                'REMOTE_HOST' => job.owner_host
            } if env.nil?

            @settings.log.scheduler_instance_dispatched( env, instance['url'] )
            @settings.log.scheduler_instance_owner_assigned( env, job.url )

            arachni = @settings.instances.connect( instance['url'], session, instance['token'] )

            opts = YAML::load( job.opts )

            arachni.opts.set( opts['settings'] ){
                arachni.plugins.load( opts['plugins'] ) {
                    arachni.modules.load( opts['modules'] ) {
                        arachni.framework.run{
                            @settings.log.scheduler_scan_started( env, job.url )
                            block.call( instance['url'] )
                        }
                    }
                }
            }
        }
    end

    #
    # Runs a job and removed it from the DB.
    #
    # @param    [Job]   job
    #
    def run_and_destroy( job, &block )
        run( job ){
            |url|
            job.destroy
            block.call( url ) if block_given?
        }
    end

    #
    # Returns all scheduled jobs.
    #
    # @return    [Array]
    #
    def jobs( *args )
        Job.all( *args )
    end

    #
    # Removes all jobs.
    #
    def delete_all
        jobs.destroy
    end

    #
    # Removed a job.
    #
    # @param    [Integer]   id
    #
    def delete( id )
        Job.get( id ).destroy
    end


    private

    def ticktock!
        ::EM.add_periodic_timer( 1 ){
            jobs.each {
                |job|
                run_and_destroy( job ) if job.datetime <= DateTime.now
            }
        }
    end

end
end
end
end
