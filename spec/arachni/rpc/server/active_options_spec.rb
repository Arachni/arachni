require 'spec_helper'

require Arachni::Options.paths.lib + 'rpc/client/instance'
require Arachni::Options.paths.lib + 'rpc/server/instance'

class Arachni::RPC::Server::Instance
    def cookies
        Arachni::HTTP::Client.cookies
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
        context 'when keys are strings' do
            it 'sets options by hash' do
                @instance.service.cookies.should be_empty

                opts = {
                    'url'   =>  'http://blah.com',
                    'scope' =>  {
                        'exclude_path_patterns'   => [ 'exclude me' ],
                        'include_path_patterns'   => [ 'include me' ],
                        'redundant_path_patterns' => { 'redundant' => 3 },
                    },
                    'datastore' => { key: 'val' },
                    'http'      => {
                        'cookies'       => { name: 'value' },
                        'cookie_string' => 'name3=value3'
                    }
                }

                @instance.opts.set( opts )

                @instance.opts.url.to_s.should == @utils.normalize_url( opts['url'] )
                @instance.opts.scope.exclude_path_patterns.should == [/exclude me/]
                @instance.opts.scope.include_path_patterns.should == [/include me/]
                @instance.opts.datastore.should == opts['datastore']

                @instance.service.cookies.should == [
                    Arachni::Cookie.new( url: opts['url'], inputs: opts['http']['cookies'] ),
                    Arachni::Cookie.new( url: opts['url'], inputs: { name3: 'value3' } )
                ]
            end
        end

        context 'when keys are symbols' do
            it 'sets options by hash' do
                @instance.service.cookies.should be_empty

                opts = {
                    url:       'http://blah2.com',
                    scope:     {
                        exclude_path_patterns:   ['exclude me2'],
                        include_path_patterns:   ['include me2'],
                        redundant_path_patterns: { 'redundant2' => 4 },
                    },
                    datastore: { key2: 'val2' },
                    http:      {
                        cookies:   { name: 'value' },
                        cookie_string: 'name3=value3'
                    }
                }
                @instance.opts.set( opts )

                @instance.opts.url.to_s.should == @utils.normalize_url( opts[:url] )
                @instance.opts.scope.exclude_path_patterns.should == [/exclude me2/]
                @instance.opts.scope.include_path_patterns.should == [/include me2/]
                @instance.opts.datastore.should == opts[:datastore]

                @instance.service.cookies.should == [
                    Arachni::Cookie.new( url: opts[:url], inputs: opts[:http][:cookies] ),
                    Arachni::Cookie.new( url: opts[:url], inputs: { name3: 'value3' } )
                ]
            end
        end
    end
end
