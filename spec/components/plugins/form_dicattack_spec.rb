require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.url = url
    end

    context "when given the right params" do
        it 'locates the form and login successfully' do
            name = name_from_filename

            options.plugins[name] = {
                'username_field' => 'username',
                'password_field' => 'password',
                'username_list'  => fixtures_path + 'usernames.txt',
                'password_list'  => fixtures_path + 'passwords.txt',
                'login_verifier' => 'logged in user!'
            }

            run
            results_for( name ).should == { username: 'sys', password: 'admin' }
        end
    end

    context "when being unable to login" do
        it 'logs nothing' do
            name = name_from_filename

            options.plugins[name] = {
                'username_field' => 'username',
                'password_field' => 'password',
                'username_list'  => fixtures_path + 'usernames.txt',
                'password_list'  => fixtures_path + 'passwords.txt',
                'login_verifier' => '34342#R#@$#2'
            }

            run
            results_for( name ).should be_nil
        end
    end

    context "when given invalid params" do
        it 'complains about not being able to find the form' do
            name = name_from_filename

            options.plugins[name] = {
                'username_field' => 'username2',
                'password_field' => 'password',
                'username_list'  => fixtures_path + 'usernames.txt',
                'password_list'  => fixtures_path + 'passwords.txt',
                'login_verifier' => 'logged in user!'
            }

            run
            results_for( name ).should be_nil
        end
    end
end
