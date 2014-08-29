require 'spec_helper'

class MockBrowserCluster
    attr_reader :result

    def handle_job_result( result )
        @result = result
    end
end

class MockWorker
    def master
        @master ||= MockBrowserCluster.new
    end
end

class JobTest < Arachni::BrowserCluster::Job
    def ran?
        !!@ran
    end

    def run
        browser.class.should == MockWorker
        @ran = true
    end
end

class JobConfigureAndRunTest < JobTest
    def run
        browser.class.should == MockWorker
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
        browser.class.should == MockWorker

        copy = self.clean_copy
        copy.browser.should == nil
        copy.id.should == self.id

        browser.class.should == MockWorker

        super
    end
end

class JobDupTest < JobTest
    attr_accessor :my_data

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
    let(:worker) { MockWorker.new }

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

    describe '#never_ending?' do
        subject { JobTest.new }

        context 'when #never_ending is' do
            context true do
                it 'returns true' do
                    subject.never_ending = true
                    subject.never_ending?.should be_true
                end
            end

            context false do
                it 'returns false' do
                    subject.never_ending = false
                    subject.never_ending?.should be_false
                end
            end

            context nil do
                it 'returns false' do
                    subject.never_ending?.should be_false
                end
            end
        end
    end

    describe '#configure_and_run' do
        subject { JobConfigureAndRunTest.new }

        it 'sets #browser' do
            subject.configure_and_run( worker )
        end

        it 'calls #run' do
            subject.ran?.should be_false
            subject.configure_and_run( worker )
            subject.ran?.should be_true
        end

        it 'removes #browser' do
            subject.ran?.should be_false
            subject.configure_and_run( worker )
            subject.browser.should be_nil
            subject.ran?.should be_true
        end
    end

    describe '#save_result' do
        subject { JobSaveResultTest.new }

        it 'forwards the result to the BrowserCluster' do
            subject.ran?.should be_false
            subject.configure_and_run( worker )
            subject.ran?.should be_true
        end
    end

    describe '#clean_copy' do
        subject { JobCleanCopyTest.new }

        it 'copies the Job without the resources set by #configure_and_run' do
            subject.ran?.should be_false
            subject.configure_and_run( worker )
            subject.ran?.should be_true
        end
    end

    describe '#dup' do
        subject { JobDupTest.new( never_ending: true, my_data: 'stuff' ) }

        it 'copies the Job' do
            subject.my_data.should == 'stuff'

            dup = subject.dup
            dup.my_data.should == 'stuff'
            dup.never_ending?.should == true
        end
    end

    describe '#forward' do
        subject { JobForwardTest.new( my_data: 'stuff' ) }

        it 'sets the original Job as the #forwarder' do
            id = subject.id
            subject.forward.forwarder.should == subject
        end

        it 'creates a new Job with the same #id' do
            id = subject.id
            subject.forward.id.should == id
        end

        it 'creates a new Job with the same #never_ending' do
            subject.forward.never_ending?.should be_false

            job = JobForwardTest.new( never_ending: true, my_data: 'stuff' )
            job.never_ending?.should be_true
            job.forward.never_ending?.should be_true

            job = JobForwardTest.new( never_ending: false, my_data: 'stuff' )
            job.never_ending?.should be_false
            job.forward.never_ending?.should be_false
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

        it 'sets the original Job as the #forwarder' do
            id = subject.id
            subject.forward_as( JobForwardAsTest ).forwarder.should == subject
        end

        it 'creates a new Job type with the same #id' do
            subject.should_not be_kind_of JobForwardAsTest

            id = subject.id

            forwarded = subject.forward_as( JobForwardAsTest )

            forwarded.id.should == id
            forwarded.should be_kind_of JobForwardAsTest
        end

        it 'creates a new Job with the same #never_ending' do
            subject.forward_as( JobForwardAsTest ).never_ending?.should be_false

            job = JobForwardTest.new( never_ending: true, my_data: 'stuff' )
            job.never_ending?.should be_true
            job.forward_as( JobForwardAsTest ).never_ending?.should be_true

            job = JobForwardTest.new( never_ending: false, my_data: 'stuff' )
            job.never_ending?.should be_false
            job.forward_as( JobForwardAsTest ).never_ending?.should be_false
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
