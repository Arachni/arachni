require_relative '../spec_helper'

describe Arachni::Framework do

    before( :all ) do
        @url = server_url_for( :auditor )
        @opts = Arachni::Options.instance
    end

    before( :each ) do
        reset_options
        @opts.dir['reports'] = spec_path + '/fixtures/reports/manager_spec/'
        @opts.dir['modules'] = spec_path + '/fixtures/taint_module/'

        @f = Arachni::Framework.new
        @f.reset
    end
    after( :each ) { @f.reset }

    describe '#opts' do
        it 'should provide access to the framework options' do
            @f.opts.is_a?( Arachni::Options ).should be_true
        end

        describe '#exclude_binaries' do
            it 'should exclude binary pages from the audit' do
                f = Arachni::Framework.new

                f.opts.url = @url + '/binary'
                f.opts.audit :links, :forms, :cookies
                f.modules.load :taint

                ok = false
                f.on_run_mods { ok = true }
                f.run
                ok.should be_true
                f.reset

                f.opts.url = @url + '/binary'
                f.opts.exclude_binaries = true
                f.modules.load :taint

                ok = true
                f.on_run_mods { ok = false }

                f.run
                f.reset
                ok.should be_true
            end
        end
        describe '#restrict_paths' do
            it 'should serve as a replacement to crawling' do
                f = Arachni::Framework.new
                f.opts.url = @url
                f.opts.restrict_paths = %w(/elem_combo /log_remote_file_if_exists/true)
                f.opts.audit_links = true
                f.opts.audit_forms = true
                f.opts.audit_cookies = true
                f.modules.load( 'taint' )

                f.run

                sitemap = f.auditstore.sitemap.sort.map { |u| u.split( '?' ).first }
                sitemap.uniq.should == f.opts.restrict_paths.sort
                f.modules.clear
            end
        end
    end

    describe '#reports' do
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

    describe '#spider' do
        it 'should provide access to the Spider' do
            @f.spider.is_a?( Arachni::Spider ).should be_true
        end
    end

    describe '#run' do

        context 'when the page has a body which is' do
            context 'not empty' do
                it 'should run modules that audit the page body' do
                    @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                    f = Arachni::Framework.new

                    f.opts.audit_links = true
                    f.modules.load %w(body)

                    link = Arachni::Element::Link.new( 'http://test' )
                    p = Arachni::Page.new( url: 'http://test', body: 'stuff' )
                    f.push_to_page_queue( p )

                    f.run
                    f.auditstore.issues.size.should == 1
                    f.modules.clear
                end
            end
            context 'empty' do
                it 'should not run modules that audit the page body' do
                    @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                    f = Arachni::Framework.new

                    f.opts.audit_links = true
                    f.modules.load %w(body)

                    link = Arachni::Element::Link.new( 'http://test' )
                    p = Arachni::Page.new( url: 'http://test', body: '' )
                    f.push_to_page_queue( p )

                    f.run
                    f.auditstore.issues.size.should == 0
                    f.modules.clear
                end
            end
        end

        context 'when audit_links is' do
            context true do
                context 'and the page contains links' do
                    it 'should run modules that audit links' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_links = true
                        f.modules.load %w(links forms cookies headers flch)

                        link = Arachni::Element::Link.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', links: [link] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'should run modules that audit path and server' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_links = true
                        f.modules.load %w(path server)

                        link = Arachni::Element::Link.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', links: [link] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'should run modules that have not specified any elements' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_links = true
                        f.modules.load %w(nil empty)

                        link = Arachni::Element::Link.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', links: [link] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 1
                        f.modules.clear
                    end
                end
            end

            context false do
                context 'and the page contains links' do
                    it 'should not run modules that audit links' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_links = false
                        f.modules.load %w(links forms cookies headers flch)

                        link = Arachni::Element::Link.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', links: [link] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 0
                        f.modules.clear
                    end

                    it 'should run modules that audit path and server' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_links = true
                        f.modules.load %w(path server)

                        link = Arachni::Element::Link.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', links: [link] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'should run modules that have not specified any elements' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_links = true
                        f.modules.load %w(nil empty)

                        link = Arachni::Element::Link.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', links: [link] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 1
                        f.modules.clear
                    end
                end
            end

        end

        context 'when audit_forms is' do
            context true do
                context 'and the page contains forms' do
                    it 'should run modules that audit forms' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_forms = true
                        f.modules.load %w(links forms cookies headers flch)

                        form = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', forms: [form] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'should run modules that audit path and server' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_forms = true
                        f.modules.load %w(path server)

                        form = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', forms: [form] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'should run modules that have not specified any elements' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_forms = true
                        f.modules.load %w(nil empty)

                        form = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', forms: [form] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 1
                        f.modules.clear
                    end
                end
            end

            context false do
                context 'and the page contains forms' do
                    it 'should not run modules that audit forms' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_forms = false
                        f.modules.load %w(links forms cookies headers flch)

                        form = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', forms: [form] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 0
                        f.modules.clear
                    end

                    it 'should run modules that audit path and server' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_forms = false
                        f.modules.load %w(path server)

                        form = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', forms: [form] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'should run modules that have not specified any elements' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_forms = false
                        f.modules.load %w(nil empty)

                        form = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', forms: [form] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 1
                        f.modules.clear
                    end
                end
            end

        end

        context 'when audit_cookies is' do
            context true do
                context 'and the page contains cookies' do
                    it 'should run modules that audit cookies' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_cookies = true
                        f.modules.load %w(links forms cookies headers flch)

                        cookie = Arachni::Element::Cookie.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', cookies: [cookie] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'should run modules that audit path and server' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_cookies = true
                        f.modules.load %w(path server)

                        cookie = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', cookies: [cookie] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'should run modules that have not specified any elements' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_cookies = true
                        f.modules.load %w(nil empty)

                        cookie = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', cookies: [cookie] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 1
                        f.modules.clear
                    end
                end
            end

            context false do
                context 'and the page contains cookies' do
                    it 'should not run modules that audit cookies' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_cookies = false
                        f.modules.load %w(links forms cookies headers flch)

                        cookie = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', cookies: [cookie] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 0
                        f.modules.clear
                    end

                    it 'should run modules that audit path and server' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_cookies = false
                        f.modules.load %w(path server)

                        cookie = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', cookies: [cookie] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'should run modules that have not specified any elements' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_cookies = false
                        f.modules.load %w(nil empty)

                        cookie = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', cookies: [cookie] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 1
                        f.modules.clear
                    end
                end
            end

        end

        context 'when audit_headers is' do
            context true do
                context 'and the page contains headers' do
                    it 'should run modules that audit headers' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_headers = true
                        f.modules.load %w(links forms cookies headers flch)

                        header = Arachni::Element::Cookie.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', headers: [header] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'should run modules that audit path and server' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_headers = true
                        f.modules.load %w(path server)

                        header = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', headers: [header] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'should run modules that have not specified any elements' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_headers = true
                        f.modules.load %w(nil empty)

                        header = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', headers: [header] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 1
                        f.modules.clear
                    end
                end
            end

            context false do
                context 'and the page contains headers' do
                    it 'should not run modules that audit headers' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_headers = false
                        f.modules.load %w(links forms cookies headers flch)

                        header = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', headers: [header] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 0
                        f.modules.clear
                    end

                    it 'should run modules that audit path and server' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_headers = false
                        f.modules.load %w(path server)

                        header = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', headers: [header] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 2
                        f.modules.clear
                    end

                    it 'should run modules that have not specified any elements' do
                        @opts.dir['modules']  = spec_path + '/fixtures/run_mod/'
                        f = Arachni::Framework.new

                        f.opts.audit_headers = false
                        f.modules.load %w(nil empty)

                        header = Arachni::Element::Form.new( 'http://test' )
                        p = Arachni::Page.new( url: 'http://test', headers: [header] )
                        f.push_to_page_queue( p )

                        f.run
                        f.auditstore.issues.size.should == 1
                        f.modules.clear
                    end
                end
            end

        end

        context 'when it has log-in capabilities and gets logged out' do
            it 'should log-in again before continuing with the audit' do
                f = Arachni::Framework.new
                url = server_url_for( :framework ) + '/'
                f.opts.url = "#{url}/congrats"

                f.opts.audit :links, :forms
                f.modules.load_all

                f.session.login_sequence = proc do
                    res = f.http.get( url, async: false, follow_location: true ).response
                    return false if !res

                    login_form = f.forms_from_response( res ).first
                    next false if !login_form

                    login_form['username'] = 'john'
                    login_form['password'] = 'doe'
                    res = login_form.submit( async: false, update_cookies: true, follow_location: false ).response
                    return false if !res

                    true
                end

                f.session.login_check = proc do
                    !!f.http.get( url, async: false, follow_location: true ).
                        response.body.match( 'logged-in user' )
                end

                f.run
                f.auditstore.issues.size.should == 1
                f.reset
            end
        end

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
            @f.auditstore.issues.size.should == 5

            @f.auditstore.plugins['wait'][:results].should == { stuff: true }

            File.exists?( 'afr' ).should be_true
            File.exists?( 'foo' ).should be_true
            File.delete( 'foo' )
            File.delete( 'afr' )
        end
    end

    describe '#push_to_page_queue' do
        it 'should push a page to the page audit queue' do
            res = @f.http.get( @url + '/train/true', async: false ).response
            page = Arachni::Page.from_response( res, @f.opts )

            @f.opts.audit_links = true
            @f.opts.audit_forms = true
            @f.opts.audit_cookies = true

            @f.modules.load( 'taint' )

            @f.page_queue_total_size.should == 0
            @f.push_to_page_queue( page )
            @f.run
            @f.auditstore.issues.size.should == 3
            @f.page_queue_total_size.should > 0
            @f.modules.clear
        end
    end

    describe '#push_to_url_queue' do
        it 'should push a URL to the URL audit queue' do
            @f.opts.audit_links = true
            @f.opts.audit_forms = true
            @f.opts.audit_cookies = true

            @f.modules.load( 'taint' )

            @f.url_queue_total_size.should == 0
            @f.push_to_url_queue(  @url + '/link' )
            @f.run
            @f.auditstore.issues.size.should == 1
            @f.url_queue_total_size.should > 0
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
            @f.modules.load( 'taint' )
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

        context 'when the #lsmod option is set' do
            it 'should use it to filter out modules that do not match it' do
                @f.opts.lsmod = 'boo'
                @f.lsmod.size == 0

                @f.opts.lsmod = 'taint'
                @f.lsmod.size == 1
            end
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
  :tags: ["wait_string", :wait_sym]
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
  :issue: {:tags: ["distributable_string", :distributable_sym]}
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

        context 'when the #lsplug option is set' do
            it 'should use it to filter out plugins that do not match it' do
                @f.opts.lsplug = 'bad|foo'
                @f.lsplug.size == 2

                @f.opts.lsplug = 'boo'
                @f.lsplug.size == 0
            end
        end
    end

    describe '#lsrep' do
        it 'should return info on all reports' do
            loaded = @f.reports.loaded
            @f.lsrep.map { |r| r[:options] = []; r.delete( :path ); r }
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

        context 'when the #lsrep option is set' do
            it 'should use it to filter out reports that do not match it' do
                @f.opts.lsrep = 'foo'
                @f.lsrep.size == 1

                @f.opts.lsrep = 'boo'
                @f.lsrep.size == 0

            end
        end
    end

end
