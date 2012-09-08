require_relative '../../../spec_helper'

require 'timeout'
require Arachni::Options.instance.dir['lib'] + 'rpc/client/instance'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/instance'

require Arachni::Options.instance.dir['lib'] + 'rpc/server/distributor'

class Distributor
    include Arachni::RPC::Server::Framework::Distributor

    attr_reader :instances
    attr_accessor :master_url

    def initialize( token )
        @opts = Arachni::Options.instance
        @local_token = token
        @instances = []
    end

    def self_url
        @master_url
    end

    def dispatcher_url=( url )
        @opts.datastore[:dispatcher_url] = url
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
        @element_ids = []

        @server.add_handler( "framework", self )
        @server.start
    end

    def register_issues( issues, token = nil )
        return false if !valid_token?( token )
        @issues |= issues
        true
    end

    private
    def valid_token?( token )
        @token == token
    end

end

describe Arachni::RPC::Server::Framework::Distributor do
    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.audit_links = true
        @token = 'secret'

        @get_instance = proc do |opts|
            opts ||= @opts
            opts.rpc_port = random_port
            fork_em { Arachni::RPC::Server::Instance.new( opts, @token ) }
            sleep 1
            Arachni::RPC::Client::Instance.new( opts,
                "#{opts.rpc_address}:#{opts.rpc_port}", @token
            )
        end

        @distributor = Distributor.new( @token )
        2.times {
            @distributor <<  { 'url' => @get_instance.call.url, 'token' => @token }
        }

        @url = url  = 'http://test.com/'
        @url2 = url2 = 'http://test.com/test/'
        @urls = []

        url_gen = proc { |u, i| "#{u}?input_#{i}=val_#{i}" }

        10.times do |i|
            @urls << url_gen.call( url, i )
        end

        4.times do |i|
            @urls << url_gen.call( url2, i )
        end

        5.times do |i|
            @urls << url_gen.call( url, i )
        end

        14.times do |i|
            @urls << url_gen.call( url2, i )
        end

        20.times do |i|
            @urls << url_gen.call( url, i )
        end

        5.times do |i|
            @urls << url_gen.call( url2, i )
        end
    end

    describe '#map_slaves' do
        it 'should asynchronously iterate over all slaves' do
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
        it 'should asynchronously iterate over all slaves' do
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
    end

    describe '#slave_iterator' do
        it 'should return an async iterator for the slave instances' do
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
        it 'should return an async iterator for the provided array' do
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

    describe '#split_urls' do
        it 'should evenly split urls into chunks for each instance' do
            @opts.min_pages_per_instance = 10
            splits = @distributor.split_urls( @urls, 4 )

            splits.size.should == 4
            splits.flatten.uniq.size.should == @urls.uniq.size

            @opts.min_pages_per_instance = 30
            splits = @distributor.split_urls( @urls, 4 )
            splits.size.should == 2

            @opts.min_pages_per_instance = 15
            splits = @distributor.split_urls( @urls, 2 )
            splits.size.should == 2
            splits.first.size.should == splits.flatten.size/2

            @opts.min_pages_per_instance = @urls.size
            splits = @distributor.split_urls( @urls, 2 )
            splits.size.should == 1
            splits.first.size.should == splits.flatten.size
        end
    end

    describe '#build_elem_list' do
        it 'should evenly distribute elements across instances' do
            @opts.url = server_url_for( :parser )
            @opts.audit_links = true
            @opts.audit_forms = true
            @opts.audit_cookies = true
            @opts.audit_headers = true

            @url = @opts.url.to_s + '/?query_var_input=query_var_val'
            @response = Arachni::HTTP.instance.get(
                @url,
                async: false,
                remove_id: true
            ).response
            page = Arachni::Parser.new( @response, @opts ).run
            @distributor.build_elem_list( page ).size.should == 7
        end
    end

    describe '#distribute_elements' do
        it 'should evenly distribute elements across instances' do
            chunks = [[@url], [@url2]]
            elem_ids_per_page = {
                @url => %w(
                    elem
                    elem_1
                    elem_2
                ),

                @url2 => %w(
                    elem_3
                    elem_4
                    elem_4
                    elem_4
                    elem_1
                    elem_2
                )
            }
            r = @distributor.distribute_elements( chunks, elem_ids_per_page )
            r.should == [ %w(elem elem_1), %w(elem_3 elem_4 elem_2) ]

            elem_ids_per_page = {
                @url => %w(
                    elem
                    elem_1
                    elem_2
                ),

                @url2 => %w(
                    elem
                    elem_1
                    elem_2
                )
            }
            r = @distributor.distribute_elements( chunks, elem_ids_per_page )
            r.should == [ %w(elem elem_2), %w(elem_1) ]

            elem_ids_per_page = {
                @url => %w(
                    elem
                ),

                @url2 => %w(
                    elem
                )
            }
            r = @distributor.distribute_elements( chunks, elem_ids_per_page )
            r.should == [ %w(elem), [] ]

            url3 = @url + '/blah/'
            chunks = [[@url], [@url2], [url3]]
            elem_ids_per_page = {
                @url => %w(
                    elem
                ),

                @url2 => %w(
                    elem
                ),

                url3 => %w(
                    elem
                )
            }
            r = @distributor.distribute_elements( chunks, elem_ids_per_page )
            r.should == [ %w(elem), [], [] ]

            elem_ids_per_page = {
                @url => %w(
                    elem
                    elem_1
                    elem_2
                    elem_3
                    elem_4
                    elem_5
                ),

                @url2 => %w(
                    elem
                    elem_1
                    elem_6
                    elem_11
                    elem_12
                    elem_13
                ),

                url3 => %w(
                    elem
                    elem_1
                    elem_4
                    elem_2
                )
            }
            r = @distributor.distribute_elements( chunks, elem_ids_per_page )
            r.should == [ %w(elem_3 elem_5), %w(elem_6 elem_11 elem_12 elem_13),
                          %w(elem elem_1 elem_4 elem_2)]

            elem_ids_per_page = {
                @url => %w(
                    elem
                    elem_1
                    elem_2
                    elem_3
                    elem_4
                    elem_5
                ),

                @url2 => %w(
                    elem
                    elem_1
                    elem_2
                    elem_3
                    elem_4
                    elem_5
                ),

                url3 => %w(
                    elem
                    elem_1
                    elem_2
                    elem_3
                    elem_4
                    elem_5
                )
            }
            r = @distributor.distribute_elements( chunks, elem_ids_per_page )
            r.should == [ %w(elem elem_4), %w(elem_2), %w(elem_1 elem_3 elem_5)]
        end
    end

    describe '#prefered_dispatchers' do
        it 'should return a sorted list of dispatchers for HPG use taking into account their pipe IDs and load balancing metrics' do
            @opts.pool_size = 1
            opts = @opts
            port = random_port

            dispatchers = []

            opts.rpc_port = port
            exec_dispatcher( opts )

            opts.rpc_port = random_port
            dispatchers[0] = "#{opts.rpc_address}:#{opts.rpc_port}"
            exec_dispatcher( opts ) do |conf|
                conf.neighbour = "#{opts.rpc_address}:#{port}"
                conf.pipe_id = '1'
            end

            opts.rpc_port = random_port
            dispatchers[2] = "#{opts.rpc_address}:#{opts.rpc_port}"
            exec_dispatcher( opts ) do |conf|
                conf.neighbour = "#{opts.rpc_address}:#{port}"
                conf.pipe_id = '2'
                conf.weight = 3
            end

            opts.rpc_port = random_port
            exec_dispatcher( opts ) do |conf|
                conf.neighbour = "#{opts.rpc_address}:#{port}"
                conf.pipe_id = '3'
                conf.weight = 2
            end

            opts.rpc_port = random_port
            dispatchers[3] = "#{opts.rpc_address}:#{opts.rpc_port}"
            exec_dispatcher( opts ) do |conf|
                conf.neighbour = "#{opts.rpc_address}:#{port}"
                conf.pipe_id = '4'
                conf.weight = 4
            end

            opts.rpc_port = random_port
            dispatchers[1] = "#{opts.rpc_address}:#{opts.rpc_port}"
            exec_dispatcher( opts ) do |conf|
                conf.neighbour = "#{opts.rpc_address}:#{port}"
                conf.pipe_id = '3'
            end

            @distributor.dispatcher_url = "#{opts.rpc_address}:#{port}"

            q = Queue.new
            @distributor.prefered_dispatchers { |d| q << d }

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
        it 'should return a sorted list of dispatchers based on their load balancing metrics' do
            dispatchers = []
            dispatchers << { 'node' => { 'score' => 0 } }
            dispatchers << { 'node' => { 'score' => 3 } }
            dispatchers << { 'node' => { 'score' => 2 } }
            dispatchers << { 'node' => { 'score' => 1 } }

            @distributor.pick_dispatchers( dispatchers ).
                map { |d| d['node']['score'] }.should == [0, 1, 2, 3]


            @opts.max_slaves = 2
            @distributor.pick_dispatchers( dispatchers ).
                map { |d| d['node']['score'] }.should == [0, 1]
        end
    end

    describe '#spawn' do
        before( :all ) do
            @opts.rpc_port = random_port
            @opts.dir['modules'] = spec_path + 'fixtures/taint_module/'
            @master = FakeMaster.new( @opts, @token )
            @distributor.master_url = "#{@opts.rpc_address}:#{@opts.rpc_port}"

            port = random_port
            @opts.pool_size = 1
            @opts.rpc_port = port
            exec_dispatcher( @opts )

            # master's token
            @opts.datastore[:token] = @token
            @opts.url = server_url_for( :framework_hpg )
            @url = @opts.url.to_s
            @opts.mods = %w(taint)

            @dispatcher_url = "#{@opts.rpc_address}:#{port}"
        end

        after { @master.issues.clear }

        context 'when called without auditable restrictions' do
            it 'should let the slave run loose, like a simple instance' do
                q = Queue.new
                @distributor.spawn( @dispatcher_url ){ |i| q << i }
                slave_info = q.pop
                slave_info.should be_true

                slave = @distributor.connect_to_instance( slave_info )
                sleep 0.1 while slave.framework.busy?
                sleep 1

                @master.issues.size.should == 51
            end
        end
        context 'when called with auditable URL restrictions' do
            it 'should restrict the audit to these URLs' do
                urls = %w(/vulnerable?vulnerable_5=stuff5 /vulnerable?vulnerable_10=stuff10)

                absolute_urls = urls.map { |u| Arachni::Module::Utilities.normalize_url( @url + u ) }

                q = Queue.new
                @distributor.spawn( @dispatcher_url, urls: urls ){ |i| q << i }
                slave_info = q.pop
                slave_info.should be_true
                slave = @distributor.connect_to_instance( slave_info )

                slave.opts.restrict_paths.should == absolute_urls
                sleep 0.1 while slave.framework.busy?
                sleep 1

                @master.issues.size.should == 2

                vuln_urls = @master.issues.map { |i| i.url }.sort.uniq
                vuln_urls.should == absolute_urls.sort.uniq
            end
        end
        context 'when called with auditable element restrictions' do
            it 'should restrict the audit to these elements' do

                ids = []
                ids << Arachni::Element::Link.new( @url + '/vulnerable',
                    inputs: { 'vulnerable_20' => 'stuff20' }
                ).scope_audit_id
                ids << Arachni::Element::Link.new( @url + '/vulnerable',
                    inputs: { 'vulnerable_30' => 'stuff30' }
                ).scope_audit_id

                q = Queue.new
                @distributor.spawn( @dispatcher_url, elements: ids ){ |i| q << i }
                slave_info = q.pop
                slave_info.should be_true

                slave = @distributor.connect_to_instance( slave_info )
                sleep 0.1 while slave.framework.busy?
                sleep 1

                @master.issues.size.should == 2

                vuln_urls = @master.issues.map { |i| i.url }.sort.uniq
                exp_urls = %w(/vulnerable?vulnerable_20=stuff20 /vulnerable?vulnerable_30=stuff30)
                vuln_urls.should == exp_urls.map { |u| Arachni::Module::Utilities.normalize_url( @url + u ) }.
                    sort.uniq
            end
            context 'and new elements appear via the trainer' do
                it 'should override the restrictions' do
                    @opts.audit_forms = true
                    @opts.url = server_url_for( :auditor ) + '/train/default'
                    url = @opts.url.to_s

                    id = Arachni::Element::Form.new( url + '?',
                        inputs: { 'step_1' => 'form_blah_step_1' }
                    ).scope_audit_id

                    q = Queue.new
                    @distributor.spawn( @dispatcher_url, elements: [id] ){ |i| q << i }
                    slave_info = q.pop
                    slave_info.should be_true

                    slave = @distributor.connect_to_instance( slave_info )
                    sleep 0.1 while slave.framework.busy?
                    sleep 1

                    @master.issues.size.should == 8
                    #@master.issues.size.should == 1
                    #@master.issues.first.url.should ==
                    #    url + "?you_made_it=to+the+end+of+the+training"
                end
            end
        end

        context 'when called with extra page' do
            it 'should include them in the audit' do

                exp_urls = []
                links = []
                links << Arachni::Element::Link.new( @url + '/vulnerable?vulnerable_20=stuff20',
                    inputs: { 'vulnerable_20' => 'stuff20' }
                )
                links << Arachni::Element::Link.new( @url + '/vulnerable?vulnerable_30=stuff30',
                    inputs: { 'vulnerable_30' => 'stuff30' }
                )
                exp_urls |= links.map { |l| l.url }

                pages = []
                pages << Arachni::Page.new(
                    url: @url,
                    links: links
                )

                links = []
                links << Arachni::Element::Link.new( @url + '/vulnerable?vulnerable_12=stuff12',
                    inputs: { 'vulnerable_12' => 'stuff12' }
                )
                links << Arachni::Element::Link.new( @url + '/vulnerable?vulnerable_23=stuff23',
                    inputs: { 'vulnerable_23' => 'stuff23' }
                )

                exp_urls |= links.map { |l| l.url }

                pages << Arachni::Page.new(
                    url: @url,
                    links: links
                )

                # send it somewhere that doesn't exist
                @opts.url = @url + '/foo'
                q = Queue.new
                @distributor.spawn( @dispatcher_url, pages: pages ){ |i| q << i }
                slave_info = q.pop
                slave_info.should be_true

                slave = @distributor.connect_to_instance( slave_info )
                sleep 0.1 while slave.framework.busy?
                sleep 1

                @master.issues.size.should == 4

                vuln_urls = @master.issues.map { |i| i.url }.sort.uniq
                vuln_urls.should == exp_urls.sort
            end
        end
    end

end
