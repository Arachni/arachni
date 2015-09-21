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
            expect(@instance.service.cookies).to be_empty

            opts = {
                'url'   =>  'http://blah.com',
                'scope' =>  {
                    'exclude_path_patterns'   => [ 'exclude me' ],
                    'include_path_patterns'   => [ 'include me' ],
                    'redundant_path_patterns' => { 'redundant' => 3 },
                },
                'datastore' => { 'key' => 'val' },
                'http'      => {
                    'cookies'       => {
                        'name'  => 'value',
                        'name2' => 'value2'
                    },
                    'cookie_string' => 'name3=value3;name4=value4'
                }
            }

            @instance.options.set( opts )
            h = @instance.options.to_h

            expect(h['url'].to_s).to eq(@utils.normalize_url( opts['url'] ))
            expect(h['scope']['exclude_path_patterns']).to eq( opts['scope']['exclude_path_patterns'] )
            expect(h['scope']['include_path_patterns']).to eq( opts['scope']['include_path_patterns'] )
            expect(h['scope']['redundant_path_patterns']).to eq( opts['scope']['redundant_path_patterns'] )

            expect(h['datastore']).to eq(opts['datastore'])

            expect(@instance.service.cookies.map { |c| Arachni::Cookie.from_rpc_data c }).to eq([
                Arachni::Cookie.new( url: opts['url'], inputs: { 'name'  => 'value' } ),
                Arachni::Cookie.new( url: opts['url'], inputs: { 'name2'  => 'value2' } ),
                Arachni::Cookie.new( url: opts['url'], inputs: { 'name3'  => 'value3' } ),
                Arachni::Cookie.new( url: opts['url'], inputs: { 'name4'  => 'value4' } )
            ])
        end
    end
end
