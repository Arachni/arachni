require_relative '../spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.plugins[name] = {
            'username_list'  => spec_path + 'fixtures/usernames.txt',
            'password_list'  => spec_path + 'fixtures/passwords.txt',
        }
    end

    def results
        results_for( name_from_filename )
    end

    context "when given the right params" do
        it 'should locate the form and login successfully' do
            options.url = server_url_for( name_from_filename )
            run
            results.should == { username: 'admin', password: 'pass' }
        end
    end

    context "when being unable to login" do
        it 'should not log any results' do
            options.url = server_url_for( "#{name_from_filename}_secure" )
            run
            results.should be_nil
        end
    end

    context "when the page isn't protected" do
        it 'should not log anything' do
            options.url = server_url_for( "#{name_from_filename}_unprotected" )
            run
            results.should be_nil
        end
    end
end
