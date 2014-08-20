require 'spec_helper'

require Arachni::Options.paths.lib + 'rpc/client/instance'
require Arachni::Options.paths.lib + 'rpc/server/instance'

describe Arachni::RPC::Server::ActiveOptions do
    before( :all ) do
        @utils = Arachni::Utilities
        @instance = instance_spawn
    end

    before( :each ) { @instance.service.clear_cookies }

    describe '#set' do
        it 'sets options by hash' do
            @instance.service.cookies.should be_empty

            opts = {
                'url'   =>  'http://blah.com',
                'scope' =>  {
                    'exclude_path_patterns'   => [ 'exclude me' ],
                    'include_path_patterns'   => [ 'include me' ],
                    'redundant_path_patterns' => { 'redundant' => 3 },
                },
                'datastore' => { 'key' => 'val' },
                'http'      => {
                    'cookies'       => { 'name' => 'value' },
                    'cookie_string' => 'name3=value3'
                }
            }

            @instance.options.set( opts )
            h = @instance.options.to_h

            h['url'].to_s.should == @utils.normalize_url( opts['url'] )
            h['scope']['exclude_path_patterns'].should ==
                opts['scope']['exclude_path_patterns'].map { |s| Regexp.new(s).to_s }
            h['scope']['include_path_patterns'].should ==
                opts['scope']['include_path_patterns'].map { |s| Regexp.new(s).to_s }
            h['scope']['redundant_path_patterns'].should ==
                opts['scope']['redundant_path_patterns'].
                    inject({}) { |hh, (k, v)| hh[Regexp.new(k).to_s] = v.to_s; hh }

            h['datastore'].should == opts['datastore']

            @instance.service.cookies.map { |c| Arachni::Cookie.from_rpc_data c }.should == [
                Arachni::Cookie.new( url: opts['url'], inputs: opts['http']['cookies'] ),
                Arachni::Cookie.new( url: opts['url'], inputs: { name3: 'value3' } )
            ]
        end
    end
end
