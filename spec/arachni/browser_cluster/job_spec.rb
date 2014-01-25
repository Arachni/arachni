require 'spec_helper'

class MockBrowserCluster
    attr_reader :result

    def handle_job_result( result )
        @result = result
    end
end

class MockPeer
    def master
        @master ||= MockBrowserCluster.new
    end
end

class JobTest < Arachni::BrowserCluster::Job
    def ran?
        !!@ran
    end

    def run
        browser.class.should == MockPeer
        @ran = true
    end
end

class JobConfigureAndRunTest < JobTest
    def run
        browser.class.should == MockPeer
        super
    end
end

class JobSaveResultTest < JobTest
    class Result < Arachni::BrowserCluster::Job::Result
        attr_accessor :my_data
    end

    def run
        val = 'stuff'
        save_result my_data: val

        result = browser.master.result
        result.job.id.should == self.id
        result.my_data.should == val

        super
    end
end

class JobCleanCopyTest < JobTest
    def run
        browser.class.should == MockPeer

        copy = self.clean_copy
        copy.browser.should == nil
        copy.id.should == self.id

        browser.class.should == MockPeer

        super
    end
end

class JobDupTest < JobTest
    attr_reader :my_data

    def initialize( options )
        super options
        @my_data = options.delete( :my_data )
    end
end

class JobForwardTest < JobDupTest
end

class JobForwardAsTest < JobForwardTest
end

describe Arachni::BrowserCluster::Job do
    let(:browser_cluster) { MockBrowserCluster.new }
    let(:peer) { MockPeer.new }

    describe '#id' do
        it 'gets incremented with each initialization' do
            id = nil
            10.times do |i|
                id = described_class.new.id
                next if i == 0

                described_class.new.id.should == id + 1
            end
        end
    end

    describe '#configure_and_run' do
        subject { JobConfigureAndRunTest.new }

        it 'sets #browser' do
            subject.configure_and_run( peer )
        end

        it 'calls #run' do
            subject.ran?.should be_false
            subject.configure_and_run( peer )
            subject.ran?.should be_true
        end

        it 'removes #browser' do
            subject.ran?.should be_false
            subject.configure_and_run( peer )
            subject.browser.should be_nil
            subject.ran?.should be_true
        end
    end

    describe '#save_result' do
        subject { JobSaveResultTest.new }

        it 'forwards the result to the BrowserCluster' do
            subject.ran?.should be_false
            subject.configure_and_run( peer )
            subject.ran?.should be_true
        end
    end

    describe '#clean_copy' do
        subject { JobCleanCopyTest.new }

        it 'copies the Job without the resources set by #configure_and_run' do
            subject.ran?.should be_false
            subject.configure_and_run( peer )
            subject.ran?.should be_true
        end
    end

    describe '#dup' do
        subject { JobDupTest.new( my_data: 'stuff' ) }

        it 'copies the Job' do
            subject.my_data.should == 'stuff'
            subject.dup.my_data.should == 'stuff'
        end
    end

    describe '#forward' do
        subject { JobForwardTest.new( my_data: 'stuff' ) }

        it 'creates a new Job with the same #id' do
            id = subject.id
            subject.forward.id.should == id
        end

        it 'does not preserve any existing data' do
            subject.forward.my_data.should be_nil
        end

        context 'when options are given' do
            it 'sets initialization options' do
                subject.forward( my_data: 'stuff2' ).my_data.should == 'stuff2'
            end
        end
    end

    describe '#forward_as' do
        subject { JobForwardTest.new( my_data: 'stuff' ) }

        it 'creates a new Job type with the same #id' do
            subject.should_not be_kind_of JobForwardAsTest

            id = subject.id

            forwarded = subject.forward_as( JobForwardAsTest )

            forwarded.id.should == id
            forwarded.should be_kind_of JobForwardAsTest
        end

        it 'does not preserve any existing data' do
            subject.should_not be_kind_of JobForwardAsTest

            forwarded = subject.forward_as( JobForwardAsTest )

            forwarded.my_data.should be_nil
            forwarded.should be_kind_of JobForwardAsTest
        end

        context 'when options are given' do
            it 'sets initialization options' do
                subject.should_not be_kind_of JobForwardAsTest

                forwarded = subject.forward_as( JobForwardAsTest, my_data: 'stuff2' )

                forwarded.my_data.should == 'stuff2'
                forwarded.should be_kind_of JobForwardAsTest
            end
        end
    end

end
