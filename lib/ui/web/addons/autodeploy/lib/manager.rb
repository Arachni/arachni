=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'datamapper'
require 'net/ssh'

module Arachni
module UI
module Web
module Addons

class AutoDeploy

#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Manager

    include Utilities

    ARCHIVE_PATH = 'http://172.16.51.1/~zapotek/'
    ARCHIVE_NAME = 'arachni-v0.3-autodeploy'
    ARCHIVE_EXT  = '.tar.gz'

    EXEC = 'arachni_xmlrpcd'

    class Deployment
        include DataMapper::Resource

        property :id,           Serial
        property :host,         String
        property :port,         String
        property :user,         String
        property :created_at,   DateTime, :default => Time.now
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

        Deployment.auto_upgrade!
    end

    def setup( deployment, password )

        begin
            session = ssh( deployment.host, deployment.user, password )
        rescue Exception => e
            return {
                :out => e.to_s + "\n" + e.backtrace.join( "\n" ),
                :code => 1
             }
         end


        out = wget = 'wget --output-document=' + ARCHIVE_NAME + ARCHIVE_EXT +
            ' ' + ARCHIVE_PATH + ARCHIVE_NAME + ARCHIVE_EXT
        ret = ssh_exec!( session, wget )
        out += "\n" + ret[:stdout] + "\n" + ret[:stderr]

        return { :out => out, :code => ret[:code] } if ret[:code] != 0

        out += tar = 'tar xvf ' + ARCHIVE_NAME + ARCHIVE_EXT
        ret = ssh_exec!( session,  tar )
        out += "\n" + ret[:stdout] + "\n" + ret[:stderr]

        return { :out => out, :code => ret[:code] } if ret[:code] != 0

        out += "\n" + chmod = 'chmod +x ' + ARCHIVE_NAME + '/' + EXEC
        ret = ssh_exec!( session, chmod )
        out += "\n" + ret[:stdout] + "\n" + ret[:stderr]

        return { :out => out, :code => ret[:code] } if ret[:code] != 0

        return { :out => out }
    end

    def uninstall( deployment, password )

        begin
            session = ssh( deployment.host, deployment.user, password )
        rescue Exception => e
            return {
                :out => e.to_s + "\n" + e.backtrace.join( "\n" ),
                :code => 1
             }
         end

        out = "\n" + rm = "rm -rf #{ARCHIVE_NAME}*"
        ret = ssh_exec!( session, rm )
        out += "\n" + ret[:stdout] + "\n" + ret[:stderr]

        return { :out => out, :code => ret[:code] } if ret[:code] != 0

        return { :out => out }
    end

    def run( deployment, password )
        session = ssh( deployment.host, deployment.user, password )
        session.exec!( 'nohup ./' + ARCHIVE_NAME + '/' + EXEC +
            ' --port=' + deployment.port + ' > arachni-xmlrpcd-startup.log 2>&1 &' )
        sleep( 5 )
    end


    def list
        Deployment.all.reverse
    end

    def get( id )
        Deployment.get( id )
    end

    def delete( id, password )
        deployment = get( id )
        ret = uninstall( deployment, password )
        deployment.destroy
        return ret
    end

    def ssh( host, user, password )
        @@ssh ||= {}
        @@ssh[user + '@' + host] ||= Net::SSH.start( host, user, :password => password )
    end

    def ssh_exec!( ssh, command )

        stdout_data = ""
        stderr_data = ""

        exit_code   = nil
        exit_signal = nil

        ssh.open_channel do |channel|
            channel.exec(command) do |ch, success|
                unless success
                    abort "FAILED: couldn't execute command (ssh.channel.exec)"
                end

                channel.on_data {
                    |ch, data|
                    stdout_data += data
                }

                channel.on_extended_data {
                    |ch, type, data|
                    stderr_data += data
                }

                channel.on_request( "exit-status" ) {
                    |ch, data|
                    exit_code = data.read_long
                }

                channel.on_request( "exit-signal" ) {
                    |ch, data|
                    exit_signal = data.read_long
                }

            end
        end

        ssh.loop
        return {
            :stdout => stdout_data,
            :stderr => stderr_data,
            :code   => exit_code,
            :signal => exit_signal
        }
    end

end
end
end
end
end
end
