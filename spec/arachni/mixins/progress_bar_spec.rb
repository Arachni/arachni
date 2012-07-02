require_relative '../../spec_helper'
require_testee

class ProgressBarTest
    include Arachni::Mixins::ProgressBar
end

describe Arachni::Mixins::ProgressBar do

    before :all do
        @pb = ProgressBarTest.new
    end

    it 'should format seconds to hourr:min:sec' do
        @pb.format_time( '3745' ).should == '01:02:25'
    end

    it 'should calculate ETA based on progress and start-time of operation' do
        start_time = Time.at( Time.now - 3600 )
        @pb.eta( 0, start_time ).should == "--:--:--"
        @pb.eta( 10, start_time ).should == "09:00:00"
        @pb.eta( 50, start_time ).should == "01:00:00"
        @pb.eta( 70, start_time ).should == "00:25:42"
        @pb.eta( 90, start_time ).should == "00:06:40"
        @pb.eta( 100, start_time ).should == "00:00:00"
    end

    it 'should return ASCII progress-bar' do
        @pb.progress_bar( 0 ).should =~ /^0% \[=>\s+\] 100%/
        @pb.progress_bar( 50 ).should =~ /^50% \[=/
        @pb.progress_bar( 50.6 ).should =~ /^50\.6% \[=/
        @pb.progress_bar( 80 ).should =~ /^80% \[=/
        @pb.progress_bar( 84.99 ).should =~ /^84\.99% \[=/
        @pb.progress_bar( 100 ).should =~ /^100% \[=+>\] 100%/
    end

    it 'should not allow progress-bar to go beyond 100%' do
        @pb.progress_bar( 1400 ).should =~ /^100\.0% \[=+>\] 100%/
    end

end
