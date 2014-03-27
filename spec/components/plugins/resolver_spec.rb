require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        Arachni::State.issues << Factory[:issue].tap { |i| i.vector.action = 'http://localhost/' }
    end

    it 'resolves vulnerable hostnames to IP addresses' do
        run
        [{ 'localhost' => '::1' }, { 'localhost' => '127.0.0.1' }].should include( results_for( name_from_filename ))
    end

end
