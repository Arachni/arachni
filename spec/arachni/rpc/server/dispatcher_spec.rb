require 'spec_helper'
require 'fileutils'

require "#{Arachni::Options.paths.lib}/rpc/server/dispatcher"

describe Arachni::RPC::Server::Dispatcher do
    before( :all ) do
        @job_info_keys  = %w(token pid port url owner birthdate starttime helpers currtime age runtime)
        @node_info_keys = %w(url pipe_id weight nickname cost)
    end

    after( :each )  do
        dispatcher_killall
        reset_options
    end

    describe '#alive?' do
        it 'returns true' do
            dispatcher_light_spawn.alive?.should == true
        end
    end

    describe '#preferred' do
        context 'when the dispatcher is a grid member' do
            it 'returns the URL of least burdened Dispatcher' do
                dispatcher = dispatcher_light_spawn( weight: 1 )
                dispatcher_light_spawn( weight: 2, neighbour: dispatcher.url )
                dispatcher_light_spawn( weight: 3, neighbour: dispatcher.url )

                dispatcher.preferred.should == dispatcher.url
            end
        end

        context 'when the dispatcher is not a grid member' do
            it 'returns the URL of the Dispatcher' do
                dispatcher = dispatcher_light_spawn
                dispatcher.preferred.should == dispatcher.url
            end
        end
    end

    describe '#handlers' do
        it 'returns an array of loaded handlers' do
            Arachni::Options.paths.services = "#{fixtures_path}services/"
            dispatcher_light_spawn.services.include?( 'echo' ).should be_true
        end
    end

    describe '#dispatch' do
        it 'does not leak Instances' do
            dispatcher = dispatcher_spawn

            times = 20
            times.times do
                sleep 0.1 while !dispatcher.dispatch
            end

            dispatcher.jobs.size.should == times
        end

        context 'when Options#dispatcher_external_address has been set' do
            it 'advertises that address' do
                address = '127.0.0.1'
                dispatcher = dispatcher_light_spawn( external_address: address )
                dispatcher.dispatch['url'].should start_with "#{address}:"
            end
        end
        context 'when not a Grid member' do
            it 'returns valid Instance info' do
                info = dispatcher_light_spawn.dispatch

                %w(token pid port url owner birthdate starttime helpers).each do |k|
                    info[k].should be_true
                end

                instance = instance_connect( info['url'], info['token'] )
                instance.service.alive?.should be_true
            end
            it 'assigns an optional owner' do
                owner = 'blah'
                dispatcher_light_spawn.dispatch( owner )['owner'].should == owner
            end
            context 'when the pool is empty' do
                it 'returns false' do
                    dispatcher = dispatcher_light_spawn
                    dispatcher.dispatch.should be_kind_of Hash
                    dispatcher.dispatch.should be_false
                end

                it 'replenishes the pool' do
                    dispatcher = dispatcher_light_spawn
                    dispatcher.dispatch.should be_kind_of Hash
                    dispatcher.dispatch.should be_false

                    hash = nil
                    Timeout.timeout 10 do
                        loop do
                            break if (hash = dispatcher.dispatch).is_a? Hash
                        end
                    end

                    hash.should be_kind_of Hash
                end
            end
        end

        context 'when a Grid member' do
            it 'returns Instance info from the least burdened Dispatcher' do
                d1 = dispatcher_spawn(
                    address: '127.0.0.1',
                    weight:  3
                )

                d2 = dispatcher_spawn(
                    address:   '127.0.0.2',
                    weight:    2,
                    neighbour: d1.url
                )

                d3 = dispatcher_spawn(
                    address:   '127.0.0.3',
                    weight:    1,
                    neighbour: d1.url
                )
                preferred = d3.url.split( ':' ).first

                d3.dispatch['url'].split( ':' ).first.should == preferred
                %W{127.0.0.3 127.0.0.2}.should include d1.dispatch['url'].split( ':' ).first
                d2.dispatch['url'].split( ':' ).first.should == preferred
                %W{127.0.0.1 127.0.0.3}.should include d3.dispatch['url'].split( ':' ).first
                %W{127.0.0.2 127.0.0.3}.should include d3.dispatch['url'].split( ':' ).first
                %W{127.0.0.2 127.0.0.3}.should include d1.dispatch['url'].split( ':' ).first
            end

            context 'when the load-balance option is set to false' do
                it 'returns an Instance from the requested Dispatcher' do
                    d1 = dispatcher_light_spawn(
                        address: '127.0.0.1',
                        weight:  1,
                    )

                    dispatcher_light_spawn(
                        address:   '127.0.0.2',
                        weight:    1,
                        neighbour: d1.url
                    )

                    d3 = dispatcher_light_spawn(
                        address:   '127.0.0.3',
                        weight:    9,
                        neighbour: d1.url
                    )

                    d3.dispatch( nil, {}, false )['url'].
                        split( ':' ).first.should == '127.0.0.3'
                end
            end
        end
    end

    describe '#job' do
        it 'returns proc info by PID' do
            dispatcher = dispatcher_light_spawn

            job = dispatcher.dispatch
            info = dispatcher.job( job['pid'] )
            @job_info_keys.each do |k|
                info[k].should be_true
            end
        end
    end

    describe '#jobs' do
        it 'returns proc info by PID for all jobs' do
            dispatcher = dispatcher_light_spawn

            dispatcher.jobs.each do |job|
                @job_info_keys.each do |k|
                    job[k].should be_true
                end
            end
        end
    end

    describe '#running_jobs' do
        it 'returns proc info for running jobs' do
            dispatcher = dispatcher_spawn

            3.times { dispatcher.dispatch }

            dispatcher.running_jobs.size.should == 3
        end
    end

    describe '#finished_jobs' do
        it 'returns proc info for finished jobs' do
            dispatcher = dispatcher_spawn

            3.times { Arachni::Processes::Manager.kill dispatcher.dispatch['pid'] }

            dispatcher.finished_jobs.size.should == 3
        end
    end

    describe '#workload_score' do
        it 'returns a float signifying the amount of workload' do
            dispatcher = dispatcher_light_spawn( weight: 4 )

            dispatcher.workload_score.should ==
                ((dispatcher.running_jobs.size + 1) * 4).to_f
        end
    end

    describe '#statistics' do
        it 'returns general statistics' do
            dispatcher = dispatcher_light_spawn

            dispatcher.dispatch
            jobs = dispatcher.jobs
            Arachni::Processes::Manager.kill( jobs.first['pid'] )

            stats = dispatcher.statistics

            %w(running_jobs finished_jobs init_pool_size node consumed_pids
                neighbours snapshots).each do |k|
                stats[k].should be_true
            end

            finished = stats['finished_jobs']
            finished.size.should == 1

            stats['neighbours'].is_a?( Array ).should be_true

            stats['node'].delete( 'score' ).should == dispatcher.workload_score
            stats['node'].keys.should == @node_info_keys
        end

        context 'when there are scan snapshots' do
            it 'lists them' do
                dispatcher = dispatcher_light_spawn
                info = dispatcher.dispatch

                instance = Arachni::RPC::Client::Instance.new(
                    Arachni::Options.instance, info['url'], info['token']
                )

                instance.service.scan( url: web_server_url_for( :framework_multi ) )
                instance.service.suspend
                sleep 1 while !instance.service.suspended?
                instance.service.shutdown

                dispatcher.statistics['snapshots'].should include instance.service.snapshot_path
            end
        end

        context "when #{Arachni::OptionGroups::Dispatcher}#external_address has been set" do
            it 'advertises that address' do
                address = '127.0.0.1'
                dispatcher = dispatcher_light_spawn( external_address: address )
                dispatcher.statistics['node']['url'].should start_with "#{address}:"
            end
        end
    end

    describe '#log' do
        it 'returns the contents of the log file' do
            dispatcher_light_spawn.log.should be_true
        end
    end

end
