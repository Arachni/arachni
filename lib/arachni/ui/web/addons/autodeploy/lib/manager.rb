=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'datamapper'
require 'net/ssh'
require 'net/scp'
require 'digest/md5'


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
# @version: 0.1.2
#
class Manager

    include Utilities

    ARCHIVE_PATH = 'https://github.com/downloads/Zapotek/arachni/'
    # ARCHIVE_PATH = 'http://localhost/~zapotek/'
    ARCHIVE_NAME = 'arachni-v' + Arachni::VERSION + '-autodeploy'
    ARCHIVE_EXT  = '.tar.gz'

    NODE_SSL_KEY  = "node_ssl_key.pem"
    NODE_SSL_CERT = "node_ssl_cert.pem"
    SSL_KEY  = "ssl_key.pem"
    SSL_CERT = "ssl_cert.pem"
    SSL_CA   = "ssl_ca.pem"


    EXEC = 'arachni_rpcd'

    class Deployment
        include DataMapper::Resource

        property :id,               Serial

        property :host,             String
        property :port,             Integer
        property :user,             String
        property :pool_size,        Integer, :default => 5

        property :dispatcher_port,  Integer, :default => 7331
        property :nickname,         String
        property :weight,           String
        property :pipe_id,          String
        property :neighbour,        String
        property :address,          String

        property :ssl,              Boolean

        property :alive,            Boolean
        property :created_at,       DateTime, :default => Time.now

        validates_numericality_of :pool_size, :gt => 0
        validates_numericality_of :dispatcher_port, :gt => 0
        validates_numericality_of :port, :gt => 0
    end

    def initialize( opts, settings )
        @opts     = opts
        @settings = settings

        DataMapper::setup( :default, "sqlite3://#{@settings.db}/default.db" )
        DataMapper.finalize

        Deployment.auto_upgrade!
    end

    def setup( deployment, password )

        @@setup ||= {}
        url = get_url( deployment )
        @@setup[url] ||= {}

        Thread.new {
            @@setup[url][:deployment] ||= deployment
            @@setup[url][:status] = 'working'

            begin
                session = ssh( deployment, password )
            rescue Exception => e
                @@setup[url][:status] = 'failed'
                @@setup[url][:output] = e.class.name + ': ' + e.to_s + "\n" + e.backtrace.join( "\n" )
                @@setup[url][:code]   = 1
                return
            end


            wget = 'wget --output-document=' + ARCHIVE_NAME + '-' + deployment.dispatcher_port.to_s +
                ARCHIVE_EXT + ' ' + ARCHIVE_PATH + ARCHIVE_NAME + ARCHIVE_EXT
            ret = ssh_exec!( deployment, session, wget )

            if ret[:code] != 0
                @@setup[url][:status] = 'failed'
                return
            end

            mkdir = 'mkdir ' + ARCHIVE_NAME + '-' + deployment.dispatcher_port.to_s
            ret = ssh_exec!( deployment, session,  mkdir )

            if ret[:code] != 0
                @@setup[url][:status] = 'failed'
                return
            end


            tar = 'tar xvf ' + ARCHIVE_NAME + '-' + deployment.dispatcher_port.to_s + ARCHIVE_EXT +
                ' -C ' + ARCHIVE_NAME + '-' + deployment.dispatcher_port.to_s
            ret = ssh_exec!( deployment, session,  tar )

            if ret[:code] != 0
                @@setup[url][:status] = 'failed'
                return
            end

            chmod = 'chmod +x ' + ARCHIVE_NAME + '-' + deployment.dispatcher_port.to_s + '/' +
                ARCHIVE_NAME + '/' + EXEC
            ret = ssh_exec!( deployment, session, chmod )

            upload_ssl_pems!( deployment, session )

            if ret[:code] != 0
                @@setup[url][:status] = 'failed'
                return
            end

            @@setup[url][:status] = 'finished'
        }

        return get_url( deployment )
    end

    def output( channel )
        return @@setup[channel]
    end

    def finalize_setup( channel )
        @@setup[channel][:deployment].ssl = @settings.conf['ssl']['server']['enable']
        @@setup[channel][:deployment].save
        return @@setup[channel][:deployment]
    end

    def uninstall( deployment, password )

        begin
            session = ssh( deployment, password )
        rescue Exception => e
            return {
                :output => e.class.name + ': ' + e.to_s + "\n" + e.backtrace.join( "\n" ),
                :status => 'failed',
                :code   => 1
             }
         end

        out = "\n" + rm = "rm -rf #{ARCHIVE_NAME}-#{deployment.dispatcher_port}*"
        ret = ssh_exec!( deployment, session, rm )
        out += "\n" + ret[:stdout] + "\n" + ret[:stderr]

        return { :output => out, :code => ret[:code], :status => 'failed', } if ret[:code] != 0

        return { :output => out }
    end

    def run( deployment, password )
       begin
           session = ssh( deployment, password )
       rescue Exception => e
           return {
               :output => e.class.name + ': ' + e.to_s + "\n" + e.backtrace.join( "\n" ),
               :status => 'failed',
               :code   => 1
           }
       end

        cmd  = 'nohup ./' + ARCHIVE_NAME + '-' + deployment.dispatcher_port.to_s + '/' + ARCHIVE_NAME + '/' + EXEC
        cmd += " --port='#{deployment.dispatcher_port}'"

        if deployment.nickname && !deployment.nickname.empty?
            cmd += " --nickname='#{deployment.nickname}'"
        end

        if deployment.pipe_id && !deployment.pipe_id.empty?
            cmd += " --pipe-id='#{deployment.pipe_id}'"
        end

        if deployment.weight && !deployment.weight.empty?
            cmd += " --weight='#{deployment.weight}'"
        end

        if deployment.neighbour && !deployment.neighbour.empty?
            cmd += " --neighbour='#{deployment.neighbour}'"
        end

        if deployment.address && !deployment.address.empty?
            cmd += " --address='#{deployment.address}'"
        end

        if deployment.pool_size > 0
            cmd += " --pool-size='#{deployment.pool_size}'"
        end

        if deployment.ssl
            cmd += " --node-ssl-pkey='/#{NODE_SSL_KEY}'"
            cmd += " --node-ssl-cert='/#{NODE_SSL_CERT}'"
            cmd += " --ssl-pkey='/#{SSL_KEY}'"
            cmd += " --ssl-cert='/#{SSL_CERT}'"
            cmd += " --ssl-ca='/#{SSL_CA}'"
        end

        # puts cmd

        cmd += ' > ' + EXEC + '-startup.log 2>&1 &'

        session.exec!( cmd )

       sleep( 3 )
       { :code   => 0 }
    end

    def shutdown( deployment, password, &block )
       url =  "#{deployment.host}:#{deployment.dispatcher_port}"
       @settings.dispatchers.connect( url ).proc_info {
           |proc|
           begin
               session = ssh( deployment, password )
           rescue Exception => e
               block.call( {
                   :output => e.class.name + ': ' + e.to_s + "\n" + e.backtrace.join( "\n" ),
                   :status => 'failed',
                   :code   => 1
               })
               next
           end

            block.call ssh_exec!( deployment, session, 'kill -9 -' + proc['pgrp'] )
        }
    end


    def list
        Deployment.all.reverse
    end

    def list_with_liveness( &block )
        ::EM.synchrony do
            deployments = ::EM::Synchrony::Iterator.new( list ).map {
                |deployment, iter|
                alive?( deployment ){
                    |alive|
                    deployment.alive = alive
                    iter.return( deployment )
                }
            }

            block.call( deployments )
        end
    end

    def alive?( deployment, &block )
        @settings.dispatchers.alive?( get_rpc_url( deployment ) ){
            |alive|
            block.call( alive )
        }
    end

    def get( id )
        Deployment.get( id )
    end

    def delete( id, password )
        deployment = get( id )
        ret = uninstall( deployment, password )
        return ret if ret[:code]
        deployment.destroy
        return ret
    end

    def ssh( deployment, password )
        @@ssh ||= {}
        @@ssh[get_url( deployment ) + '$' + Digest::MD5.hexdigest( password ) ] ||=
            Net::SSH.start( deployment.host, deployment.user,
                {
                  :port     => deployment.port,
                  :password => password
                }
            )
    end

    def get_rpc_url( deployment )
        deployment.host + ':' + deployment.dispatcher_port.to_s
    end

    def get_url( deployment )
        deployment.user + '@' + deployment.host + ':' + deployment.port.to_s +
            '$' + deployment.dispatcher_port.to_s
    end

    def upload_ssl_pems!( deployment, ssh )

        if !@settings.conf['ssl']['client']['enable'] ||
            !@settings.conf['ssl']['server']['enable']
            return
        end

        dir = ARCHIVE_NAME + '-' + deployment.dispatcher_port.to_s + '/' +
            ARCHIVE_NAME + '/cde-root/'

        tx = []
        tx << ssh.scp.upload( @settings.conf['ssl']['client']['key'], dir + NODE_SSL_KEY )
        tx << ssh.scp.upload( @settings.conf['ssl']['client']['cert'], dir + NODE_SSL_CERT )
        tx << ssh.scp.upload( @settings.conf['ssl']['server']['key'], dir + SSL_KEY )
        tx << ssh.scp.upload( @settings.conf['ssl']['server']['cert'], dir + SSL_CERT )
        tx << ssh.scp.upload( @settings.conf['ssl']['server']['ca'], dir + SSL_CA )

        tx.each { |d| d.wait }
    end

    def ssh_exec!( deployment, ssh, command )

        stdout_data = ""
        stderr_data = ""

        exit_code   = nil
        exit_signal = nil

        @@setup ||= {}

        url = get_url( deployment )

        @@setup[url] ||= {}
        @@setup[url][:code]   = 0
        @@setup[url][:output] ||= ''
        @@setup[url][:output] += "\n" + command + "\n"

        ssh.open_channel do |channel|
            channel.exec(command) do |ch, success|
                unless success
                    abort "FAILED: couldn't execute command (ssh.channel.exec)"
                end

                channel.on_data {
                    |ch, data|
                    stdout_data += data
                    @@setup[url][:output] += data
                }

                channel.on_extended_data {
                    |ch, type, data|
                    stderr_data += data
                    @@setup[url][:output] += data
                }

                channel.on_request( "exit-status" ) {
                    |ch, data|
                    exit_code = data.read_long
                    @@setup[url][:code] = data.read_long
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
