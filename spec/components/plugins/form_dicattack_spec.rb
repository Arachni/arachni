require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.url = url
    end

    context 'when given the right params' do
        it 'locates the form and login successfully' do
            options.plugins[component_name] = {
                'username_field' => 'username',
                'password_field' => 'password',
                'username_list'  => fixtures_path + 'usernames.txt',
                'password_list'  => fixtures_path + 'passwords.txt',
                'login_verifier' => 'logged in user!'
            }

            run
            expect(actual_results).to eq({ 'username' => 'sys', 'password' => 'admin' })
        end
    end

    context 'when being unable to login' do
        it 'logs nothing' do
            options.plugins[component_name] = {
                'username_field' => 'username',
                'password_field' => 'password',
                'username_list'  => fixtures_path + 'usernames.txt',
                'password_list'  => fixtures_path + 'passwords.txt',
                'login_verifier' => '34342#R#@$#2'
            }

            run
            expect(actual_results).to be_nil
        end
    end

    context 'when given invalid params' do
        it 'complains about not being able to find the form' do
            options.plugins[component_name] = {
                'username_field' => 'username2',
                'password_field' => 'password',
                'username_list'  => fixtures_path + 'usernames.txt',
                'password_list'  => fixtures_path + 'passwords.txt',
                'login_verifier' => 'logged in user!'
            }

            run
            expect(actual_results).to be_nil
        end
    end
end
