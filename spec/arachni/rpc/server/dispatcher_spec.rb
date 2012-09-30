require_relative '../../../spec_helper'
require 'fileutils'

require Arachni::Options.dir['lib'] + 'rpc/client/dispatcher'
require Arachni::Options.dir['lib'] + 'rpc/server/dispatcher'

describe Arachni::RPC::Server::Dispatcher do
    before( :all ) do
        @opts = Arachni::Options.instance

        @opts.pool_size = 1
        @opts.rpc_port = random_port
        @opts.pipe_id = '#1'
        @opts.weight = 4
        @opts.nickname = 'blah'
        @opts.cost = 12

        FileUtils.cp( "#{fixtures_path}rpcd_handlers/echo.rb",
                      Arachni::Options.dir['rpcd_handlers'] )

        fork_em {
            Arachni::RPC::Server::Dispatcher.new( @opts )
        }
        sleep 1

        @url = "#{@opts.rpc_address}:#{@opts.rpc_port}"
        @dispatcher = Arachni::RPC::Client::Dispatcher.new( @opts, @url )

        @job_info_keys = %w(token pid port url owner birthdate starttime helpers currtime age runtime proc)
        @node_info = {
            "url"      => "#{@opts.rpc_address}:#{@opts.rpc_port}",
            "pipe_id"  => @opts.pipe_id,
            "weight"   => @opts.weight,
            "nickname" => @opts.nickname,
            "cost"     => @opts.cost
        }
    end

    after( :all ) do
        FileUtils.rm( "#{Arachni::Options.dir['rpcd_handlers']}echo.rb" )
        @dispatcher.stats['consumed_pids'].each { |p| pids << p }
    end

    describe '#alive?' do
        it 'should return true' do
            @dispatcher.alive?.should == true
        end
    end

    describe '#handlers' do
        it 'should return an array of loaded handlers' do
            @dispatcher.handlers.include?( 'echo' ).should be_true
        end
    end

    describe '#dispatch' do
        it 'should return valid Instance info' do
            info = @dispatcher.dispatch

            %w(token pid port url owner birthdate starttime helpers).each do |k|
                info[k].should be_true
            end

            instance = Arachni::RPC::Client::Instance.new( @opts, info['url'], info['token'] )
            instance.service.alive?.should be_true
        end
        it 'should assign an optional owner' do
            owner = 'blah'
            info = @dispatcher.dispatch( owner )
            info['owner'].should == owner
        end
        it 'should replenish the pool' do
            10.times {
                info = @dispatcher.dispatch
                info['pid'].should be_true
            }
        end
    end

    describe '#job' do
        it 'should return proc info by PID' do
            job = @dispatcher.dispatch
            info = @dispatcher.job( job['pid'] )
            @job_info_keys.each do |k|
                info[k].should be_true
            end
        end
    end

    describe '#jobs' do
        it 'should return proc info by PID for all jobs' do
            @dispatcher.jobs.each do |job|
                @job_info_keys.each do |k|
                    job[k].should be_true
                end
            end
        end
    end

    describe '#stats' do
        it 'should return general statistics' do
            jobs = @dispatcher.jobs
            Process.kill( 'KILL', jobs.first['pid'] )

            stats = @dispatcher.stats

            %w(running_jobs finished_jobs init_pool_size node consumed_pids neighbours).each do |k|
                stats[k].should be_true
            end

            finished = stats['finished_jobs']
            finished.size.should == 1

            stats['neighbours'].is_a?( Array ).should be_true

            stats['node'].delete( 'score' ).is_a?( Float ).should be_true
            stats['node'].should == @node_info
        end
    end

    describe '#log' do
        it 'should return the contents of the log file' do
            @dispatcher.log.should be_true
        end
    end

    describe '#proc_info' do
        it 'should return the proc info of the dispatcher' do
            info = @dispatcher.proc_info
            info.should be_true

            info['node'].should == @node_info
        end
    end

end
