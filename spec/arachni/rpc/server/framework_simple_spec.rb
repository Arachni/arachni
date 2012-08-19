require_relative '../../../spec_helper'

require 'json'

require Arachni::Options.instance.dir['lib'] + 'rpc/client/instance'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/instance'

describe Arachni::RPC::Server::Framework do
    before( :all ) do
        @opts = Arachni::Options.instance
        @token = 'secret!'

        @get_instance = proc do |opts|
            opts ||= @opts
            port = random_port
            opts.rpc_port = port
            fork_em { Arachni::RPC::Server::Instance.new( opts, @token ) }
            sleep 1
            Arachni::RPC::Client::Instance.new( opts,
                "#{opts.rpc_address}:#{port}", @token
            )
        end

        @instance = @get_instance.call
        @framework = @instance.framework
        @modules = @instance.modules
        @plugins = @instance.plugins

        @instance_clean = @get_instance.call
        @framework_clean = @instance_clean.framework
    end

    describe '#busy?' do
        context 'when the scan is not running' do
            it 'should return false' do
                @framework_clean.busy?.should be_false
            end
        end
        context 'when the scan is running' do
            it 'should return true' do
                @instance.opts.url = server_url_for( :auditor ) + '/sleep'
                @modules.load( 'test' )
                @framework.run.should be_true
                @framework.busy?.should be_true
            end
        end
    end
    describe '#version' do
        it 'should return the system version' do
            @framework_clean.version.should == Arachni::VERSION
        end
    end
    describe '#revision' do
        it 'should return the framework revision' do
            @framework_clean.revision.should == Arachni::Framework::REVISION
        end
    end
    describe '#high_performance?' do
        it 'should return false' do
            @framework_clean.high_performance?.should be_false
        end
    end
    describe '#lsplug' do
        it 'should list all available plugins' do
            plugins = @framework_clean.lsplug
            plugins.size.should == 6
            plugin = plugins.select { |i| i[:name] =~ /default/i }.first
            plugin[:name].should == 'Default'
            plugin[:description].should == 'Some description'
            plugin[:author].size.should == 1
            plugin[:author].first.should == 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>'
            plugin[:version].should == '0.1'
            plugin[:plug_name].should == 'default'
            plugin[:options].size.should== 1
            opt = plugin[:options].first
            opt['name'].should == 'int_opt'
            opt['required'].should == false
            opt['desc'].should == 'An integer.'
            opt['default'].should == 4
            opt['enums'].should be_empty
            opt['type'].should == 'integer'
        end
    end
    describe '#lsmod' do
        it 'should list all available plugins' do
            @framework_clean.lsmod.should be_any
        end
    end
    describe '#output' do
        it 'should return the instance\'s output messages' do
            output = @framework_clean.output.first
            output.keys.first.is_a?( Symbol ).should be_true
            output.values.first.is_a?( String ).should be_true
        end
    end
    describe '#run' do
        it 'should perform a scan' do
            instance = @instance_clean
            instance.opts.url = server_url_for( :framework_simple )
            instance.modules.load( 'test' )
            instance.framework.run.should be_true
            sleep( 1 ) while instance.framework.busy?
            instance.framework.issues.should be_any
        end
    end
    describe '#auditstore' do
        it 'should return an auditstore object' do
            auditstore = @instance_clean.framework.auditstore
            auditstore.is_a?( Arachni::AuditStore ).should be_true
            auditstore.issues.should be_any
            issue = auditstore.issues.first
            issue.is_a?( Arachni::Issue ).should be_true
            issue.variations.should be_any
            issue.variations.first.is_a?( Arachni::Issue ).should be_true
        end
    end
    describe '#stats' do
        it 'should return a hash containing general runtime statistics' do
            instance = @instance_clean
            instance.opts.url = server_url_for( :framework_simple )
            instance.modules.load( 'test' )
            instance.framework.run.should be_true

            stats = instance.framework.stats
            stat_keys = [
                :requests, :responses, :time_out_count,
                :time, :avg, :sitemap_size, :auditmap_size, :progress, :curr_res_time,
                :curr_res_cnt, :curr_avg, :average_res_time, :max_concurrency,
                :current_page, :eta
            ]
            stats.keys.should == stat_keys
            stat_keys.each { |k| stats[k].should be_true }
        end
    end
    describe '#paused?' do
        context 'when not paused' do
            it 'should return false' do
                instance = @instance_clean
                instance.framework.paused?.should be_false
            end
        end
        context 'when paused' do
            it 'should return true' do
                instance = @instance_clean
                instance.framework.pause
                instance.framework.paused?.should be_true
            end
        end
    end
    describe '#resume' do
        it 'should resume the scan' do
            instance = @instance_clean
            instance.framework.pause
            instance.framework.paused?.should be_true
            instance.framework.resume.should be_true
            instance.framework.paused?.should be_false
        end
    end
    describe '#status' do
        before( :all ) do
            @inst = @get_instance.call
            @inst.opts.url = server_url_for( :framework_simple ) + '/crawl'
            @inst.modules.load( 'test' )
        end
        context 'after initialization' do
            it 'should return "ready"' do
                @inst.framework.status.should == 'ready'
            end
        end
        context 'after "run" has been called' do
            context 'and the scanner is crawling' do
                it 'should return "crawling"' do
                    @inst.framework.run.should be_true
                    sleep 2
                    @inst.framework.status.should == 'crawling'
                end
            end
            context 'and the scanner is paused' do
                it 'should return "paused"' do
                    @inst.framework.pause
                    @inst.framework.status.should == 'paused'
                    @inst.framework.resume
                end
            end
        end
        context 'during audit' do
            it 'should return "audit"' do
                mod_lib = @opts.dir['modules'].dup
                @opts.dir['modules'] = spec_path + '/fixtures/wait_module/'

                inst = @get_instance.call
                inst.opts.url = server_url_for( :framework_simple )
                inst.opts.audit_headers = true
                inst.modules.load( 'wait' )
                inst.framework.run
                sleep 2
                inst.framework.status.should == 'auditing'

                @opts.dir['modules'] = mod_lib.dup
            end
        end
        context 'once the scan had completed' do
            it 'should return "done"' do
                inst = @get_instance.call
                inst.opts.url = server_url_for( :framework_simple )
                inst.modules.load( 'test' )
                inst.framework.run
                sleep 2
                inst.framework.status.should == 'done'
            end
        end
    end
    describe '#clean_up' do
        it 'should set the framework state to finished and wait for plugins to finish' do
            instance = @get_instance.call
            instance.opts.url = server_url_for( :framework_simple )
            instance.modules.load( 'test' )
            instance.plugins.load( { 'wait' => {} } )
            instance.framework.run.should be_true
            instance.framework.busy?.should be_true
            instance.framework.auditstore.plugins.should be_empty
            instance.framework.clean_up.should be_true
            results = instance.framework.auditstore.plugins
            results.should be_any
            results['wait'].should be_any
            results['wait'][:results].should == { stuff: true }
        end
    end
    describe '#progress' do
        before { @progress_keys = %W(stats status busy issues instances messages).sort }

        it 'should be aliased to #progress_data' do
            instance = @instance_clean
            data = instance.framework.progress_data
            data.keys.sort.should == @progress_keys
        end

        context 'when called without options' do
            it 'should return all progress data' do
                instance = @instance_clean

                data = instance.framework.progress
                data.keys.sort.should == @progress_keys

                data['stats'].should be_any
                data['stats'].keys.should ==
                    instance.framework.stats.keys.map { |s| s.to_s }
                data['instances'].should be_empty
                data['status'].should be_true
                data['busy'].nil?.should be_false
                data['messages'].is_a?( Array ).should be_true
                data['issues'].should be_any
                data['instances'].should be_empty
            end
        end

        context 'when called with option' do
            describe :messages do
                context 'when set to false' do
                    it 'should exclude messages' do
                        keys = @instance_clean.framework. progress( messages: false ).
                            keys.sort
                        pk = @progress_keys.dup
                        pk.delete( "messages" )
                        keys.should == pk
                    end
                end
            end
            describe :issue do
                context 'when set to false' do
                    it 'should exclude issues' do
                        keys = @instance_clean.framework. progress( issues: false ).
                            keys.sort
                        pk = @progress_keys.dup
                        pk.delete( "issues" )
                        keys.should == pk
                    end
                end
            end
            describe :slaves do
                context 'when set to false' do
                    it 'should exclude issues' do
                        keys = @instance_clean.framework. progress( slaves: false ).
                            keys.sort
                        pk = @progress_keys.dup
                        pk.delete( "instances" )
                        keys.should == pk
                    end
                end
            end
            describe :as_hash do
                context 'when set to true' do
                    it 'should include issues as a hash' do
                        @instance_clean.framework.
                            progress( as_hash: true )['issues']
                            .first.is_a?( Hash ).should be_true
                    end
                end
            end
        end
    end
    describe '#report' do
        it 'should return a hash report of the scan' do
            report = @instance_clean.framework.report
            report.is_a?( Hash ).should be_true
            report['issues'].should be_any

            issue = report['issues'].first
            issue.is_a?( Hash ).should be_true
            issue['variations'].should be_any
            issue['variations'].first.is_a?( Hash ).should be_true
        end

        it 'should be alised to #audit_store_as_hash' do
            @instance_clean.framework.report.should ==
                @instance_clean.framework.audit_store_as_hash
        end
        it 'should be alised to #auditstore_as_hash' do
            @instance_clean.framework.report.should ==
                @instance_clean.framework.auditstore_as_hash
        end
    end

    describe '#report_as' do
        context 'when passed a valid report name' do
            it 'should return the report as a string' do
                json = @instance_clean.framework.report_as( :json )
                JSON.load( json )['issues'].size.should == @instance_clean.framework.auditstore.issues.size
            end
        end

        context 'when passed an valid report name which does not support the \'outfile\' option' do
            it 'should raise an exception' do
                raised = false
                begin
                    @instance_clean.framework.report_as( :stdout )
                rescue Exception
                    raised = true
                end
                raised.should be_true
            end
        end

        context 'when passed an invalid report name' do
            it 'should raise an exception' do
                raised = false
                begin
                    @instance_clean.framework.report_as( :blah )
                rescue Exception
                    raised = true
                end
                raised.should be_true
            end
        end
    end

    describe '#serialized_auditstore' do
        it 'should return a YAML serialized AuditStore' do
            yaml_str = @instance_clean.framework.serialized_auditstore
            YAML.load( yaml_str ).is_a?( Arachni::AuditStore ).should be_true
        end
    end
    describe '#serialized_report' do
        it 'should return a YAML serialized report hash' do
            yaml_str = @instance_clean.framework.serialized_report
            YAML.load( yaml_str ).should == @instance_clean.framework.report
        end
    end
    describe '#issues' do
        it 'should return an array of issues without variations' do
            issues = @instance_clean.framework.issues
            issues.should be_any

            issue = issues.first
            issue.is_a?( Arachni::Issue ).should be_true
            issue.variations.should be_empty
        end
    end
    describe '#issues_as_hash' do
        it 'should return an array of issues (as hash) without variations' do
            issues = @instance_clean.framework.issues_as_hash
            issues.should be_any

            issue = issues.first
            issue.is_a?( Hash ).should be_true
            issue['variations'].should be_empty
        end
    end

    describe '#restrict_to_elements' do
        it 'should restrict the audit to the provided element signatures' do
            mod_lib = @opts.dir['modules'].dup
            @opts.dir['modules'] = spec_path + '/fixtures/taint_module/'

            inst = @get_instance.call( @opts)
            inst.opts.url = server_url_for( :framework_simple ) + '/restrict_to_elements'
            inst.opts.audit_links = true
            inst.modules.load( 'taint' )

            opts = { async: false, remove_id: true }
            res = Arachni::HTTP.instance.get( inst.opts.url.to_s, opts ).response

            link = Arachni::Element::Link.from_response( res ).pop
            inst.framework.restrict_to_elements(  [ link.scope_audit_id ] ).should be_true

            inst.framework.run.should be_true
            sleep 0.1 while inst.framework.busy?

            issues = inst.framework.issues
            issues.size.should == 1
            issues.first.var.should == link.auditable.keys.first
        end
    end
    describe '#update_page_queue' do
        it 'should push the provided page objects to the page audit queue' do
            url = server_url_for( :framework_simple )
            inst = @get_instance.call
            inst.opts.url = url
            inst.opts.audit_links = true
            inst.modules.load( 'taint' )

            opts = { async: false, remove_id: true }
            url_to_audit = url +  '/restrict_to_elements'
            res = Arachni::HTTP.instance.get( url_to_audit, opts ).response

            page = Arachni::Page.from_response( res, @opts )
            inst.framework.update_page_queue( [ page ] ).should be_true

            inst.framework.run.should be_true
            sleep 0.1 while inst.framework.busy?

            inst.framework.issues.size.should == 2
        end
    end
    describe '#register_issues' do
        it 'should register an issue with the instance' do
            url = server_url_for( :framework_simple )
            inst = @get_instance.call
            inst.opts.url = url

            issue = Arachni::Issue.new( name: 'stuff', url: url, elem: 'link' )
            inst.framework.register_issues( [issue] ).should be_true

            issues = inst.framework.issues
            issues.size.should == 1

            issue = issues.first
            issue.name.should == issue.name
            issue.var.should == issue.var
            issue.elem.should == issue.elem
        end
    end
end
