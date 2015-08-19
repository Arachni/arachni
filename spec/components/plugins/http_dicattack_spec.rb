require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.plugins[name] = {
            'username_list'  => fixtures_path + 'usernames.txt',
            'password_list'  => fixtures_path + 'passwords.txt',
        }
    end

    def results
        results_for( name_from_filename )
    end

    context 'when given the right params' do
        it 'logins successfully' do
            options.url = web_server_url_for( name_from_filename )
            run
            expect(results).to eq({ 'username' => 'admin', 'password' => 'pass' })
        end
    end

    context 'when being unable to login' do
        it 'logs nothing' do
            options.url = web_server_url_for( "#{name_from_filename}_secure" )
            run
            expect(results).to be_nil
        end
    end

    context "when the page isn't protected" do
        it 'logs nothing' do
            options.url = web_server_url_for( "#{name_from_filename}_unprotected" )
            run
            expect(results).to be_nil
        end
    end
end
