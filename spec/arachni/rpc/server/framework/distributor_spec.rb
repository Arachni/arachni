require 'spec_helper'
require Arachni::Options.paths.lib + 'rpc/server/base'
require Arachni::Options.paths.lib + 'rpc/server/framework'

class Distributor
    include Arachni::RPC::Server::Framework::Distributor

    attr_reader   :instances
    attr_accessor :master_url

    [ :map_slaves, :each_slave, :slave_iterator, :iterator_for, :preferred_dispatchers,
      :pick_dispatchers, :distribute_and_run, :cleaned_up_opts ].each do |sym|
        private sym
        public sym
    end

    def initialize( token )
        @opts           = Arachni::Options.instance
        @local_token    = token
        @instances      = []
        @running_slaves = Set.new
    end

    def dispatcher_url=( url )
        @opts.datastore.dispatcher_url = url
    end

    def <<( instance_h )
        @instances << instance_h
    end
end

class FakeMaster

    attr_reader :issues

    def initialize( opts, token )
        @opts  = opts
        @token = token
        @server = Arachni::RPC::Server::Base.new( @opts, token )

        @pages  = []
        @issues = []
        @element_ids     = []

        @server.add_handler( 'framework', self )
        @server.start
    end

    def enslave( instance_hash )
        instance = Arachni::RPC::Client::Instance.new( @opts,
                                                       instance_hash['url'],
                                                       instance_hash['token'])

        instance.framework.
            set_master( "#{@server.opts[:host]}:#{@server.opts[:port]}", @token )
    end

    def slave_sitrep( data, url, token = nil )
        return false if !valid_token?( token )
        @issues |= data[:issues] || []
        true
    end

    private

    def valid_token?( token )
        @token == token
    end

end

describe Arachni::RPC::Server::Framework::Distributor do
    before( :all ) do
        @opts             = Arachni::Options.instance
        @opts.audit.links = true
        @token            = 'secret'

        @distributor = Distributor.new( @token )
        2.times {
            instance = instance_spawn
            @distributor <<  {
                'url'   => instance.url,
                'token' => instance_token_for( instance.url )
            }
        }

        @url  = 'http://test.com/'
        @url2 = 'http://test.com/test/'
        @urls = []

        url_gen = proc { |u, i| "#{u}?input_#{i}=val_#{i}" }

        10.times do |i|
            @urls << url_gen.call( @url, i )
        end

        4.times do |i|
            @urls << url_gen.call( @url2, i )
        end

        5.times do |i|
            @urls << url_gen.call( @url, i )
        end

        14.times do |i|
            @urls << url_gen.call( @url2, i )
        end

        20.times do |i|
            @urls << url_gen.call( @url, i )
        end

        5.times do |i|
            @urls << url_gen.call( @url2, i )
        end
    end

    describe '#cleaned_up_opts' do
        it 'returns a hash with options suitable for passing to slaves' do
            @distributor.cleaned_up_opts.should == {
                http:      {
                    user_agent:             @opts.http.user_agent,
                    request_timeout:        50000,
                    request_redirect_limit: 5,
                    request_concurrency:    20,
                    request_queue_size:     500,
                    request_headers:        {},
                    cookies:                {}
                },
                audit:     {
                    exclude_vectors: [],
                    links:           true
                },
                login:     {},
                datastore: {
                    master_priv_token: 'secret'
                },
                output:    {},
                scope:     {
                    redundant_path_patterns: {},
                    dom_depth_limit:         10,
                    exclude_path_patterns:   [],
                    exclude_page_patterns:   [],
                    include_path_patterns:   [],
                    restrict_paths:          [],
                    extend_paths:            []
                },
                checks:    [],
                platforms: [],
                reports:   {},
                plugins:   {},
                no_fingerprinting: false,
                authorized_by:     nil
            }
        end
    end

    describe '#map_slaves' do
        it 'asynchronously maps all slaves' do
            q = Queue.new

            foreach = proc { |instance, iter| instance.service.alive? { |res| iter.return( res ) } }
            after = proc { |res| q << res }

            @distributor.map_slaves( foreach, after )

            raised = false
            begin
                Timeout::timeout( 5 ) { q.pop.should == [true, true] }
            rescue Timeout::Error
                raised = true
            end
            raised.should be_false
        end
    end

    describe '#each_slave' do
        it 'asynchronously iterates over all slaves' do
            q = Queue.new

            foreach = proc do |instance, iter|
                instance.service.alive? do |res|
                    q << res
                    iter.next
                end
            end
            @distributor.each_slave( &foreach )

            raised = false
            begin
                Timeout::timeout( 5 ) { [q.pop, q.pop].should == [true, true] }
            rescue Timeout::Error
                raised = true
            end
            raised.should be_false
        end

        context 'when passed an "after" block' do
            it 'calls it after the iteration has completed' do
                q = Queue.new

                foreach = proc do |instance, iter|
                    instance.service.alive? do |res|
                        q << res
                        iter.next
                    end
                end
                after = proc { q << :after }

                @distributor.each_slave( foreach, after )

                raised = false
                begin
                    Timeout::timeout( 5 ) { [q.pop, q.pop, q.pop].should == [true, true, :after] }
                rescue Timeout::Error
                    raised = true
                end
                raised.should be_false
            end

        end
    end

    describe '#slave_iterator' do
        it 'returns an async iterator for the slave instances' do
            q = Queue.new

            foreach = proc do |instance, iter|
                q << instance['url']
                iter.next
            end
            @distributor.slave_iterator.each( &foreach )

            urls = @distributor.instances.map { |i| i['url'] }.sort

            raised = false
            begin
                Timeout::timeout( 5 ) { [q.pop, q.pop].sort.should == urls }
            rescue Timeout::Error
                raised = true
            end
            raised.should be_false
        end
    end

    describe '#iterator_for' do
        it 'returns an async iterator for the provided array' do
            q = Queue.new

            foreach = proc do |instance, iter|
                q << instance['url']
                iter.next
            end
            @distributor.iterator_for( @distributor.instances ).each( &foreach )

            urls = @distributor.instances.map { |i| i['url'] }.sort

            raised = false
            begin
                Timeout::timeout( 5 ) { [q.pop, q.pop].sort.should == urls }
            rescue Timeout::Error
                raised = true
            end
            raised.should be_false
        end
    end

    describe '#preferred_dispatchers' do
        it 'returns a sorted list of dispatchers for HPG use taking into account their pipe IDs and load balancing metrics' do
            dispatchers = []


            d1 = dispatcher_light_spawn

            dispatchers << dispatcher_light_spawn(
                pipe_id: '1',
                neighbour: d1.url
            ).url

            dispatchers << dispatcher_light_spawn(
                pipe_id:   '3',
                neighbour: d1.url
            ).url

            dispatcher_light_spawn(
                weight:  3,
                pipe_id: '1',
                neighbour: d1.url
            )

            dispatchers << dispatcher_light_spawn(
                weight:    3,
                pipe_id:   '2',
                neighbour: d1.url
            ).url

            dispatcher_light_spawn(
                weight:    2,
                pipe_id:   '3',
                neighbour: d1.url
            )

            dispatchers << dispatcher_light_spawn(
                weight:    4,
                pipe_id:   '4',
                neighbour: d1.url
            ).url

            @distributor.dispatcher_url = d1.url

            q = Queue.new
            @distributor.preferred_dispatchers { |d| q << d }

            pref_dispatchers = []

            raised = false
            begin
                Timeout.timeout( 10 ) { pref_dispatchers = q.pop }
            rescue TimeoutError
                raised = true
            end

            raised.should be_false

            pref_dispatchers.size.should == 4
            pref_dispatchers.should == dispatchers
        end
    end

    describe '#pick_dispatchers' do
        it 'returns a sorted list of dispatchers based on their load balancing metrics' do
            dispatchers = []
            dispatchers << { 'node' => { 'score' => 0 } }
            dispatchers << { 'node' => { 'score' => 3 } }
            dispatchers << { 'node' => { 'score' => 2 } }
            dispatchers << { 'node' => { 'score' => 1 } }

            @distributor.pick_dispatchers( dispatchers ).
                map { |d| d['node']['score'] }.should == [0, 1, 2, 3]

            @opts.spawns = 2
            @distributor.pick_dispatchers( dispatchers ).
                map { |d| d['node']['score'] }.should == [0, 1]
        end
    end

    describe '#distribute_and_run' do
        #before( :all ) do
        #    @opts.paths.checks = fixtures_path + 'taint_check/'
        #
        #    @dispatcher_url = dispatcher_light_spawn.url
        #
        #    @opts.rpc.server_port   = available_port
        #    @master                 = FakeMaster.new( @opts, @token )
        #    @distributor.master_url = "#{@opts.rpc.server_address}:#{@opts.rpc.server_port}"
        #
        #    # master's token
        #    @opts.datastore.token = @token
        #    @opts.url             = web_server_url_for( :framework_hpg )
        #    @url                  = @opts.url
        #    @opts.checks          = %w(taint)
        #
        #    @get_instance_info = proc do
        #        instance = instance_spawn( token: @token, port: nil )
        #        info = {
        #            'url'   => instance.url,
        #            'token' => instance_token_for( instance )
        #        }
        #        @master.enslave( info )
        #        info
        #    end
        #end
        #
        #after do
        #    @master.issues.clear
        #end

        context 'when called with auditable URL restrictions' do
            it 'restricts the audit to these URLs'
        end
        context 'when called with auditable element restrictions' do
            it 'restricts the audit to these elements'
            context 'and new elements appear via the trainer' do
                it 'overrides the restrictions'
            end
        end

        context 'when called with extra pages' do
            it 'includes them in the audit'
        end
    end

end
