require 'spec_helper'

require Arachni::Options.paths.lib + 'rpc/client/instance'
require Arachni::Options.paths.lib + 'rpc/server/instance'

class Arachni::RPC::Server::Instance
    def cookies
        Arachni::HTTP::Client.cookies.map(&:to_rpc_data)
    end
    def clear_cookies
        Arachni::Options.reset
        Arachni::HTTP::Client.cookie_jar.clear
        true
    end
end

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

            @instance.opts.set( opts )
            h = @instance.opts.to_h

            h['url'].to_s.should == @utils.normalize_url( opts['url'] )
            h['scope']['exclude_path_patterns'].should == opts['scope']['exclude_path_patterns']
            h['scope']['include_path_patterns'].should == opts['scope']['include_path_patterns']
            h['scope']['redundant_path_patterns'].should == opts['scope']['redundant_path_patterns']
            h['datastore'].should == opts['datastore']

            @instance.service.cookies.map { |c| Arachni::Cookie.from_rpc_data c }.should == [
                Arachni::Cookie.new( url: opts['url'], inputs: opts['http']['cookies'] ),
                Arachni::Cookie.new( url: opts['url'], inputs: { name3: 'value3' } )
            ]
        end
    end
end
