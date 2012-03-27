require_relative '../../../spec_helper'

require Arachni::Options.instance.dir['lib'] + 'rpc/client/dispatcher'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/dispatcher'

describe Arachni::RPC::Server::Dispatcher do
    before( :all ) do
        kill_em!
        @opts = Arachni::Options.instance
        @opts.rpc_address = 'localhost'
        @opts.dir['logs'] = spec_path + 'logs'
        port1 = random_port
        port2 = random_port


        @pids = []
        @pids << ::EM.fork_reactor {
            @opts.pool_size = 1
            @opts.rpc_port = port2
            Arachni::RPC::Server::Dispatcher.new( @opts )
        }
        sleep 1

        @dispatcher = Arachni::RPC::Client::Dispatcher.new( @opts, "#{@opts.rpc_address}:#{port2}" )

        @job_info_keys = [ 'token', 'pid', 'port', 'url', 'owner',
           'birthdate', 'starttime', 'helpers', 'currtime',
           'age', 'runtime', 'proc' ]
    end

    after( :all ){
        @pids.each { |p| Process.kill( 'KILL', p ) }
        @opts.reset!
    }

    describe :alive? do
        it 'should return true' do
            @dispatcher.alive?.should == true
        end
    end

    describe :dispatch do
        it 'should return valid Instance info' do
            info = @dispatcher.dispatch

            [ 'token', 'pid', 'port', 'url', 'owner',
                'birthdate', 'starttime', 'helpers' ].each {
                |k|
                info[k].should be_true
            }

            instance = Arachni::RPC::Client::Instance.new( @opts, info['url'], info['token'] )
            instance.service.alive?.should be_true

            @pids << info['pid']
        end
        it 'should assign an optional owner' do
            owner = 'blah'
            info = @dispatcher.dispatch( owner )
            info['owner'].should == owner
            @pids << info['pid']
        end
        it 'should replenish the pool' do
            10.times {
                info = @dispatcher.dispatch
                info['pid'].should be_true
                @pids << info['pid']
            }

        end
    end

    describe :job do
        it 'should return proc info by PID' do
            job = @dispatcher.dispatch
            info = @dispatcher.job( job['pid'] )
            @job_info_keys.each {
                |k|
                info[k].should be_true
            }

            @pids << info['pid']
        end
    end

    describe :jobs do
        it 'should return proc info by PID for all jobs' do
            @dispatcher.jobs.each {
                |job|
                @job_info_keys.each {
                    |k|
                    job[k].should be_true
                }
            }
        end
    end

    describe :stats do
        it 'should return general statistics' do
            jobs = @dispatcher.jobs
            Process.kill( 'KILL', jobs.first['pid'] )

            stats = @dispatcher.stats

            [ 'running_jobs', 'finished_jobs', 'init_pool_size', 'node' ].each {
                |k|
                stats[k].should be_true
            }

            finished = stats['finished_jobs']
            finished.size.should == 1
        end
    end

    describe :log do
        it 'should return the contents of the log file' do
            @dispatcher.log.should be_true
        end
    end

    describe :proc_info do
        it 'should return the proc info of the dispatcher' do
            @dispatcher.proc_info.should be_true
        end
    end


end
