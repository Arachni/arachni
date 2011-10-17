=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'datamapper'
require Arachni::Options.instance.dir['lib'] + 'rpc/client/dispatcher'
require Arachni::Options.instance.dir['lib'] + 'ui/web/utilities'

module Arachni
module UI
module Web

#
# Schedules and executes scan jobs.
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
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

        begin
            ticktock!
        rescue Exception => e
            # ap e
            # ap e.backtrace
        end
    end

    #
    # Runs a job.
    #
    # @param    [Job]   job
    # @param    [Hash]  Sinatra environment
    # @param    [Hash]  Rack session
    #
    # @return   [String]    URL of the laucnhed scanner instance
    #
    def run( job, env = nil, session = nil, &block )
        raise( "This method requires a block!" ) if !block_given?

        @settings.dispatchers.connect( job.dispatcher ).dispatch( job.url ){
            |instance|

            env = {
                'REMOTE_ADDR' => job.owner_addr,
                'REMOTE_HOST' => job.owner_host
            } if env.nil?

            @settings.log.scheduler_instance_dispatched( env, instance['url'] )
            @settings.log.scheduler_instance_owner_assigned( env, job.url )

            arachni = @settings.instances.connect( instance['url'], session, instance['token'] )

            opts = YAML::load( job.opts )

            arachni.opts.set( opts['settings'] ){
                arachni.modules.load( opts['modules'] ) {
                    arachni.framework.run{
                        @settings.log.scheduler_scan_started( env, job.url )
                        block.call( instance['url'] )
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
    def run_and_destroy( job )
        run( job )
        job.destroy
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
        @reaper ||= Thread.new {
            while( true )
                jobs.each {
                    |job|

                    begin
                        run_and_destroy( job ) if job.datetime <= Time.now
                    rescue Exception => e
                        # ap e
                        # ap e.backtraces
                    end

                }

                ::IO::select( nil, nil, nil, 5 )
            end
        }

    end

end
end
end
end
