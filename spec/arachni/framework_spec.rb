require_relative '../spec_helper'

describe Arachni::Framework do

    before( :all ) do
        opts = Arachni::Options.instance
        opts.dir['reports'] = spec_path + '/fixtures/reports/manager_spec/'
        opts.dir['modules']  = spec_path + '/fixtures/taint_module/'
        @f = Arachni::Framework.new

        @url = server_url_for( :auditor )
    end

    after( :all ) do
        @f.modules.clear
        @f.reports.clear
        @f.plugins.clear
    end

    describe '#opts' do
        it 'should provide access to the framework options' do
            @f.opts.is_a?( Arachni::Options ).should be_true
        end
    end

    describe '#report' do
        it 'should provide access to the report manager' do
            @f.reports.is_a?( Arachni::Report::Manager ).should be_true
            @f.reports.available.sort.should == %w(afr foo).sort
        end
    end

    describe '#modules' do
        it 'should provide access to the module manager' do
            @f.modules.is_a?( Arachni::Module::Manager ).should be_true
            @f.modules.available.should == %w(taint)
        end
    end

    describe '#plugins' do
        it 'should provide access to the plugin manager' do
            @f.plugins.is_a?( Arachni::Plugin::Manager ).should be_true
            @f.plugins.available.sort.should == %w(wait bad with_options distributable loop default).sort
        end
    end

    describe '#http' do
        it 'should provide access to the HTTP interface' do
            @f.http.is_a?( Arachni::HTTP ).should be_true
        end
    end

    describe '#run' do
        it 'should perform the audit' do
            @f.opts.url = @url + '/elem_combo'
            @f.opts.audit_links = true
            @f.opts.audit_forms = true
            @f.opts.audit_cookies = true
            @f.modules.load( 'taint' )
            @f.plugins.load( 'wait' )
            @f.reports.load( 'foo' )

            @f.status.should == 'ready'

            @f.pause
            @f.status.should == 'paused'

            @f.resume
            @f.status.should == 'ready'

            called = false
            t = Thread.new{
                @f.run {
                    called = true
                    @f.status.should == 'cleanup'
                }
            }

            raised = false
            begin
                Timeout.timeout( 10 ) {
                    sleep( 0.01 ) while @f.status == 'preparing'
                    sleep( 0.01 ) while @f.status == 'crawling'
                    sleep( 0.01 ) while @f.status == 'auditing'
                }
            rescue TimeoutError
                raised = true
            end

            raised.should be_false

            t.join
            called.should be_true

            @f.status.should == 'done'
            @f.auditstore.issues.size.should == 3

            File.exists?( 'afr' ).should be_true
            File.exists?( 'foo' ).should be_true
            File.delete( 'foo' )
            File.delete( 'afr' )
        end
    end

    describe '#push_to_page_queue' do
        it 'should push a page to the page audit queue' do
            res = @f.http.get( @url + '/train/true', async: false ).response
            page = Arachni::Parser::Page.from_response( res, @f.opts )
            @f.page_queue_total_size.should == 0
            @f.push_to_page_queue( page )
            @f.run
            @f.auditstore.issues.size.should == 4
            @f.page_queue_total_size.should == 2
        end
    end

    describe '#push_to_url_queue' do
        it 'should push a URL to the URL audit queue' do
            @f.url_queue_total_size.should == 10
            @f.push_to_url_queue(  @url + '/link' )
            @f.run
            @f.auditstore.issues.size.should == 5
            @f.url_queue_total_size.should == 16
        end
    end

    describe '#auditstore' do
        it 'should return the audit results' do
            store = @f.auditstore
            store.issues.size.should == 5
            store.plugins.include?( 'wait' ).should be_true
        end
    end

    describe '#stats' do
        it 'should return a hash with stats' do
            @f.stats.keys.sort.should == [ :requests, :responses, :time_out_count,
                :time, :avg, :sitemap_size, :auditmap_size, :progress, :curr_res_time,
                :curr_res_cnt, :curr_avg, :average_res_time, :max_concurrency, :current_page, :eta ].sort
        end
    end

    describe '#lsmod' do
        it 'should return info on all modules' do
            info = @f.modules.values.first.info
            loaded = @f.modules.loaded
            mods = @f.lsmod
            @f.modules.loaded.should == loaded

            mods.size.should == 1
            mod = mods.first
            mod[:name].should == info[:name]
            mod[:mod_name].should == 'taint'
            mod[:description].should == info[:description]
            mod[:author].should == [info[:author]].flatten
            mod[:version].should == info[:version]
            mod[:references].should == info[:references]
            mod[:targets].should == info[:targets]
            mod[:issue].should == info[:issue]
        end
    end

    describe '#lsplug' do
        it 'should return info on all plugins' do
            loaded = @f.plugins.loaded
            @f.lsplug.map { |r| r.delete( :path ); r }
                .sort_by { |e| e[:plug_name] }.should == YAML.load( '
---
- :name: Wait
  :description: ""
  :author:
  - Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
  :version: "0.1"
  :plug_name: wait
- :name: ""
  :description: ""
  :author:
  - Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
  :version: "0.1"
  :plug_name: bad
- :name: Component
  :description: Component with options
  :author:
  - Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
  :version: "0.1"
  :options:
  - !ruby/object:Arachni::Component::Options::String
    default:
    desc: Required option
    enums: []

    name: req_opt
    required: true
  - !ruby/object:Arachni::Component::Options::String
    default:
    desc: Optional option
    enums: []

    name: opt_opt
    required: false
  - !ruby/object:Arachni::Component::Options::String
    default: value
    desc: Option with default value
    enums: []

    name: default_opt
    required: false
  :plug_name: with_options
- :name: Distributable
  :description: ""
  :author:
  - Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
  :version: "0.1"
  :plug_name: distributable
- :name: ""
  :description: ""
  :author:
  - Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
  :version: "0.1"
  :plug_name: loop
- :name: Default
  :description: Some description
  :author:
  - Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
  :version: "0.1"
  :options:
  - !ruby/object:Arachni::Component::Options::Int
    default: 4
    desc: An integer.
    enums: []

    name: int_opt
    required: false
  :plug_name: default
' ).sort_by { |e| e[:plug_name] }
            @f.plugins.loaded.should == loaded
        end
    end

    describe '#lsrep' do
        it 'should return info on all reports' do
            loaded = @f.reports.loaded
            @f.lsrep.map { |r| r.delete( :path ); r }
                .sort_by { |e| e[:rep_name] }.should == YAML.load( '
---
- :name: Report abstract class.
  :options: []

  :description: This class should be extended by all reports.
  :author:
  - zapotek
  :version: 0.1.1
  :rep_name: afr
- :name: Report abstract class.
  :options: []

  :description: This class should be extended by all reports.
  :author:
  - zapotek
  :version: 0.1.1
  :rep_name: foo
').sort_by { |e| e[:rep_name] }
            @f.reports.loaded.should == loaded
        end
    end

end
