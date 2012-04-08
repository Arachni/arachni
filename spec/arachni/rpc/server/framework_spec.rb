require_relative '../../../spec_helper'

require Arachni::Options.instance.dir['lib'] + 'rpc/client/instance'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/instance'

describe Arachni::RPC::Server::Framework do
    before( :all ) do
        @opts = Arachni::Options.instance
        @token = 'secret!'

        @get_instance = proc {
            port = random_port
            fork_em {
                @opts.rpc_port = port
                Arachni::RPC::Server::Instance.new( @opts, @token )
            }
            sleep 1
            Arachni::RPC::Client::Instance.new( @opts,
                "#{@opts.rpc_address}:#{port}", @token
            )
        }

        @instance = @get_instance.call
        @framework = @instance.framework
        @modules = @instance.modules
        @plugins = @instance.plugins

        @instance_clean = @get_instance.call
        @framework_clean = @instance_clean.framework
    end

    context 'when operating in simple mode' do
        describe :busy? do
            context 'when the scan is not running' do
                it 'should return false' do
                    @framework_clean.busy?.should be_false
                end
            end
            context 'when the scan is running' do
                it 'should return true' do
                    @instance.opts.url = server_url_for( :auditor )
                    @modules.load( 'test' )
                    @framework.run.should be_true
                    @framework.busy?.should be_true
                end
            end
        end
        describe :version do
            it 'should return the system version' do
                @framework_clean.version.should == Arachni::VERSION
            end
        end
        describe :revision do
            it 'should return the framework revision' do
                @framework_clean.revision.should == Arachni::Framework::REVISION
            end
        end
        describe :high_performance? do
            it 'should return false' do
                @framework_clean.high_performance?.should be_false
            end
        end
        describe :lsplug do
            it 'should list all available plugins' do
                plugins = @framework_clean.lsplug
                plugins.size.should == 3
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
        describe :lsmod do
            it 'should list all available plugins' do
                @framework_clean.lsmod.should be_any
            end
        end
        describe :master do
            it 'should be nil' do
                @framework_clean.master.should == ''
            end
        end
        describe :output do
            it 'should return the instance\'s output messages' do
                output = @framework_clean.output.first
                output.keys.first.is_a?( Symbol ).should be_true
                output.values.first.is_a?( String ).should be_true
            end
        end
        describe :run do
            it 'should perform a scan' do
                instance = @instance_clean
                instance.opts.url = server_url_for( :framework )
                instance.modules.load( 'test' )
                instance.framework.run.should be_true
                sleep( 1 ) while instance.framework.busy?
                instance.framework.issues.should be_any
            end
        end
        describe :auditstore do
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
    end

end
