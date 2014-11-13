require 'spec_helper'

describe Arachni::State::Framework do
    after(:each) do
        FileUtils.rm_rf @dump_directory if @dump_directory
    end

    subject { described_class.new }
    before(:each) { subject.clear }

    let(:page) { Factory[:page] }
    let(:element) { Factory[:link] }
    let(:url) { page.url }
    let(:dump_directory) do
        @dump_directory = "#{Dir.tmpdir}/framework-#{Arachni::Utilities.generate_token}"
    end

    describe '#status_messages' do
        it 'returns the assigned status messages' do
            message = 'Hey!'
            subject.set_status_message message
            subject.status_messages.should == [message]
        end

        context 'by defaults' do
            it 'returns an empty array' do
                subject.status_messages.should == []
            end
        end
    end

    describe '#set_status_message' do
        it 'sets the #status_messages to the given message' do
            message = 'Hey!'
            subject.set_status_message message
            subject.set_status_message message
            subject.status_messages.should == [message]
        end
    end

    describe '#add_status_message' do
        context 'when given a message of type' do
            context String do
                it 'pushes it to #status_messages' do
                    message = 'Hey!'
                    subject.add_status_message message
                    subject.add_status_message message
                    subject.status_messages.should == [message, message]
                end
            end

            context Symbol do
                context 'and it exists in #available_status_messages' do
                    it 'pushes the associated message to #status_messages' do
                        subject.add_status_message :pausing
                        subject.status_messages.should == [subject.available_status_messages[:pausing]]
                    end
                end

                context 'and it does not exist in #available_status_messages' do
                    it "raises #{described_class::Error::InvalidStatusMessage}" do
                        expect do
                            subject.add_status_message :stuff
                        end.to raise_error described_class::Error::InvalidStatusMessage
                    end
                end

                context 'when given sprintf arguments' do
                    it 'uses them to fill in the placeholders' do
                        location = '/blah/stuff.afs'
                        subject.add_status_message :snapshot_location, location
                        subject.status_messages.should == [subject.available_status_messages[:snapshot_location] % location]
                    end
                end
            end
        end
    end

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        it 'includes #rpc statistics' do
            statistics[:rpc].should == subject.rpc.statistics
        end

        it 'includes #audited_page_count' do
            subject.audited_page_count += 1
            statistics[:audited_page_count].should == subject.audited_page_count
        end

        it 'includes amount of #browser_skip_states' do
            set = Arachni::Support::LookUp::HashSet.new
            set << 1 << 2 << 3
            subject.update_browser_skip_states( set )

            statistics[:browser_states].should == subject.browser_skip_states.size
        end
    end

    describe '#page_queue_filter' do
        it "returns an instance of #{Arachni::Support::LookUp::HashSet}" do
            subject.page_queue_filter.should be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#url_queue_filter' do
        it "returns an instance of #{Arachni::Support::LookUp::HashSet}" do
            subject.url_queue_filter.should be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#rpc' do
        it "returns an instance of #{described_class::RPC}" do
            subject.rpc.should be_kind_of described_class::RPC
        end
    end

    describe '#element_checked?' do
        context 'when an element has already been checked' do
            it 'returns true' do
                subject.element_pre_check_filter << element
                subject.element_checked?( element ).should be_true
            end
        end

        context 'when an element has not been checked' do
            it 'returns false' do
                subject.element_checked?( element ).should be_false
            end
        end
    end

    describe '#element_checked' do
        it 'marks an element as checked' do
            subject.element_checked element
            subject.element_checked?( element ).should be_true
        end
    end

    describe '#page_seen?' do
        context 'when a page has already been seen' do
            it 'returns true' do
                subject.page_queue_filter << page
                subject.page_seen?( page ).should be_true
            end
        end

        context 'when a page has not been seen' do
            it 'returns false' do
                subject.page_seen?( page ).should be_false
            end
        end
    end

    describe '#page_seen' do
        context 'when the given page has been marked as seen' do
            it 'returns true' do
                subject.page_seen page
                subject.page_seen?( page ).should be_true
            end
        end

        context 'when the given page has not been marked as seen' do
            it 'returns false' do
                subject.page_seen?( page ).should be_false
            end
        end
    end

    describe '#url_seen?' do
        context 'when a URL has already been seen' do
            it 'returns true' do
                subject.url_queue_filter << url
                subject.url_seen?( url ).should be_true
            end
        end

        context 'when a page has not been seen' do
            it 'returns false' do
                subject.url_seen?( url ).should be_false
            end
        end
    end

    describe '#url_seen' do
        context 'when the given URL has been marked as seen' do
            it 'returns true' do
                subject.url_seen url
                subject.url_seen?( url ).should be_true
            end
        end

        context 'when the given URL has not been marked as seen' do
            it 'returns false' do
                subject.url_seen?( url ).should be_false
            end
        end
    end

    describe '#running=' do
        it 'sets #running' do
            subject.running.should be_false

            subject.running = true
            subject.running.should be_true
        end
    end

    describe '#running?' do
        context 'when #running is true' do
            it 'returns true' do
                subject.running = true
                subject.should be_running
            end
        end

        context 'when #running is false' do
            it 'returns false' do
                subject.running = false
                subject.should_not be_running
            end
        end
    end

    describe '#scanning?' do
        context 'when the status is set to :scanning' do
            it 'returns true' do
                subject.status = :scanning
                subject.should be_scanning
            end
        end

        context 'when the status is not set to :scanning' do
            it 'returns false' do
                subject.should_not be_scanning
            end
        end
    end

    describe '#suspend' do
        context 'when #running?' do
            before(:each) { subject.running = true }

            context 'when blocking' do
                it 'waits for a #suspended signal' do
                    t = Thread.new do
                        sleep 1
                        subject.suspended
                    end

                    time = Time.now
                    subject.suspend
                    (Time.now - time).should > 1
                    t.join
                end

                it 'sets the #status to :suspended' do
                    t = Thread.new do
                        sleep 1
                        subject.suspended
                    end
                    subject.suspend
                    t.join

                    subject.status.should == :suspended
                end

                it 'sets the status message to :suspending' do
                    t = Thread.new do
                        sleep 1
                        subject.suspended
                    end
                    subject.suspend
                    t.join

                    subject.status_messages.should ==
                        [subject.available_status_messages[:suspending]]
                end

                it 'returns true' do
                    t = Thread.new do
                        sleep 1
                        subject.suspended
                    end
                    subject.suspend.should be_true
                    t.join

                    subject.status.should == :suspended
                end
            end

            context 'when non-blocking' do
                it 'sets the #status to :suspending' do
                    subject.suspend( false )
                    subject.status.should == :suspending
                end

                it 'sets the status message to :suspending' do
                    subject.suspend( false )
                    subject.status_messages.should ==
                        [subject.available_status_messages[:suspending]]
                end

                it 'returns true' do
                    subject.suspend( false ).should be_true
                end
            end

            context 'when already #suspending?' do
                it 'returns false' do
                    subject.suspend( false ).should be_true
                    subject.should be_suspending
                    subject.suspend.should be_false
                end
            end

            context 'when already #suspended?' do
                it 'returns false' do
                    subject.suspend( false ).should be_true
                    subject.suspended
                    subject.should be_suspended

                    subject.suspend.should be_false
                end
            end

            context 'when #pausing?' do
                it "raises #{described_class::Error::StateNotSuspendable}" do
                    subject.pause( :caller, false )

                    expect{ subject.suspend }.to raise_error described_class::Error::StateNotSuspendable
                end
            end

            context 'when #paused?' do
                it "raises #{described_class::Error::StateNotSuspendable}" do
                    subject.pause( :caller, false )
                    subject.paused

                    expect{ subject.suspend }.to raise_error described_class::Error::StateNotSuspendable
                end
            end
        end

        context 'when not #running?' do
            it "raises #{described_class::Error::StateNotSuspendable}" do
                expect{ subject.suspend }.to raise_error described_class::Error::StateNotSuspendable
            end
        end
    end

    describe '#suspended' do
        it 'sets the #status to :suspended' do
            subject.suspended
            subject.status.should == :suspended
        end
    end

    describe '#suspended?' do
        context 'when #suspended' do
            it 'returns true' do
                subject.suspended
                subject.should be_suspended
            end
        end

        context 'when not #suspended' do
            it 'returns false' do
                subject.should_not be_suspended
            end
        end
    end

    describe '#suspending?' do
        before(:each) { subject.running = true }

        context 'while suspending' do
            it 'returns true' do
                subject.suspend( false )
                subject.should be_suspending
            end
        end

        context 'while not suspending' do
            it 'returns false' do
                subject.should_not be_suspending

                subject.suspend( false )
                subject.suspended
                subject.should_not be_suspending
            end
        end
    end

    describe '#suspend?' do
        before(:each) { subject.running = true }

        context 'when a #suspend signal is in place' do
            it 'returns true' do
                subject.suspend( false )
                subject.should be_suspend
            end
        end

        context 'when a #suspend signal is not in place' do
            it 'returns false' do
                subject.should_not be_suspend

                subject.suspend( false )
                subject.suspended
                subject.should_not be_suspend
            end
        end
    end

    describe '#abort' do
        context 'when #running?' do
            before(:each) { subject.running = true }

            context 'when blocking' do
                it 'waits for an #aborted signal' do
                    t = Thread.new do
                        sleep 1
                        subject.aborted
                    end

                    time = Time.now
                    subject.abort
                    (Time.now - time).should > 1
                    t.join
                end

                it 'sets the #status to :aborted' do
                    t = Thread.new do
                        sleep 1
                        subject.aborted
                    end
                    subject.abort
                    t.join

                    subject.status.should == :aborted
                end

                it 'sets the status message to :aborting' do
                    t = Thread.new do
                        sleep 1
                        subject.aborted
                    end
                    subject.abort
                    t.join

                    subject.status_messages.should ==
                        [subject.available_status_messages[:aborting]]
                end

                it 'returns true' do
                    t = Thread.new do
                        sleep 1
                        subject.aborted
                    end
                    subject.abort.should be_true
                    t.join

                    subject.status.should == :aborted
                end
            end

            context 'when non-blocking' do
                it 'sets the #status to :aborting' do
                    subject.abort( false )
                    subject.status.should == :aborting
                end

                it 'sets the status message to :aborting' do
                    subject.abort( false )
                    subject.status_messages.should ==
                        [subject.available_status_messages[:aborting]]
                end

                it 'returns true' do
                    subject.abort( false ).should be_true
                end
            end

            context 'when already #aborting?' do
                it 'returns false' do
                    subject.abort( false ).should be_true
                    subject.should be_aborting
                    subject.abort.should be_false
                end
            end

            context 'when already #aborted?' do
                it 'returns false' do
                    subject.abort( false ).should be_true
                    subject.aborted
                    subject.should be_aborted

                    subject.abort.should be_false
                end
            end
        end

        context 'when not #running?' do
            it "raises #{described_class::Error::StateNotAbortable}" do
                expect{ subject.abort }.to raise_error described_class::Error::StateNotAbortable
            end
        end
    end

    describe '#aborted' do
        it 'sets the #status to :aborted' do
            subject.aborted
            subject.status.should == :aborted
        end
    end

    describe '#aborted?' do
        context 'when #aborted' do
            it 'returns true' do
                subject.aborted
                subject.should be_aborted
            end
        end

        context 'when not #aborted' do
            it 'returns false' do
                subject.should_not be_aborted
            end
        end
    end

    describe '#aborting?' do
        before(:each) { subject.running = true }

        context 'while aborting' do
            it 'returns true' do
                subject.abort( false )
                subject.should be_aborting
            end
        end

        context 'while not aborting' do
            it 'returns false' do
                subject.should_not be_aborting

                subject.abort( false )
                subject.aborted
                subject.should_not be_aborting
            end
        end
    end

    describe '#abort?' do
        before(:each) { subject.running = true }

        context 'when a #abort signal is in place' do
            it 'returns true' do
                subject.abort( false )
                subject.should be_abort
            end
        end

        context 'when a #abort signal is not in place' do
            it 'returns false' do
                subject.should_not be_abort

                subject.abort( false )
                subject.aborted
                subject.should_not be_abort
            end
        end
    end

    describe '#pause' do
        context 'when #running?' do
            before(:each) { subject.running = true }

            context 'when blocking' do
                it 'waits for a #paused signal' do
                    t = Thread.new do
                        sleep 1
                        subject.paused
                    end

                    time = Time.now
                    subject.pause :a_caller
                    (Time.now - time).should > 1
                    t.join
                end

                it 'sets the #status to :paused' do
                    t = Thread.new do
                        sleep 1
                        subject.paused
                    end
                    subject.pause :a_caller
                    t.join

                    subject.status.should == :paused
                end

                it 'returns true' do
                    t = Thread.new do
                        sleep 1
                        subject.paused
                    end
                    subject.pause( :a_caller ).should be_true
                    t.join

                    subject.status.should == :paused
                end
            end

            context 'when non-blocking' do
                it 'sets the #status to :pausing' do
                    subject.pause( :a_caller, false )
                    subject.status.should == :pausing
                end

                it 'sets the status message to :pausing' do
                    subject.pause( :a_caller, false )
                    subject.status_messages.should ==
                        [subject.available_status_messages[:pausing]]
                end

                it 'returns true' do
                    subject.pause( :a_caller, false ).should be_true
                end
            end
        end

        context 'when not #running?' do
            before(:each) { subject.running = false }

            it 'sets the #status directly to :paused' do
                t = Thread.new do
                    sleep 1
                    subject.paused
                end

                time = Time.now
                subject.pause :a_caller, false
                subject.status.should == :paused
                (Time.now - time).should < 1
                t.join
            end
        end
    end

    describe '#paused' do
        it 'sets the #status to :paused' do
            subject.paused
            subject.status.should == :paused
        end
    end

    describe '#pausing?' do
        before(:each) { subject.running = true }

        context 'while pausing' do
            it 'returns true' do
                subject.pause( :caller, false )
                subject.should be_pausing
            end
        end

        context 'while not pausing' do
            it 'returns false' do
                subject.should_not be_pausing

                subject.pause( :caller, false )
                subject.paused
                subject.should_not be_pausing
            end
        end
    end

    describe '#pause?' do
        context 'when a #pause signal is in place' do
            it 'returns true' do
                subject.pause( :caller, false )
                subject.should be_pause
            end
        end

        context 'when a #pause signal is not in place' do
            it 'returns false' do
                subject.should_not be_pause

                subject.pause( :caller, false )
                subject.paused
                subject.resume( :caller )
                subject.should_not be_pause
            end
        end
    end

    describe '#resume' do
        before(:each) { subject.running = true }

        it 'removes a #pause signal' do
            subject.pause( :caller, false )
            subject.pause_signals.should include :caller

            subject.resume( :caller )

            subject.pause_signals.should_not include :caller
            subject.should_not be_paused
        end

        it 'operates on a per-caller basis' do
            subject.pause( :caller, false )
            subject.pause( :caller, false )
            subject.pause( :caller, false )
            subject.paused
            subject.pause( :caller2, false )

            subject.resume( :caller )
            subject.should be_paused

            subject.resume( :caller2 )
            subject.should_not be_paused
        end

        it 'restores the previous #status' do
            subject.status = :my_status

            subject.pause( :caller, false )
            subject.paused
            subject.status == :paused

            subject.resume( :caller )
            subject.status == :my_status
        end

        context 'when called before a #pause signal has been sent' do
            it '#pause? returns false' do
                subject.pause( :caller, false )
                subject.resume( :caller )
                subject.should_not be_pause
            end

            it '#paused? returns false' do
                subject.pause( :caller, false )
                subject.resume( :caller )
                subject.should_not be_paused
            end
        end

        context 'when there are no more signals' do
            it 'returns true' do
                subject.pause( :caller, false )
                subject.paused

                subject.resume( :caller ).should be_true
            end
        end

        context 'when there are more signals' do
            it 'returns false' do
                subject.pause( :caller, false )
                subject.pause( :caller2, false )
                subject.paused

                subject.resume( :caller ).should be_false
            end
        end
    end

    describe '#browser_skip_states' do
        it "returns a #{Arachni::Support::LookUp::HashSet}" do
            subject.browser_skip_states.should be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#update_browser_skip_states' do
        it 'updates #browser_skip_states' do
            subject.browser_skip_states.should be_empty

            set = Arachni::Support::LookUp::HashSet.new
            set << 1 << 2 << 3
            subject.update_browser_skip_states( set )
            subject.browser_skip_states.should == set
        end
    end

    describe '#dump' do
        it 'stores #rpc to disk' do
            subject.dump( dump_directory )
            described_class::RPC.load( "#{dump_directory}/rpc" ).should be_kind_of described_class::RPC
        end

        it 'stores #page_queue_filter to disk' do
            subject.page_queue_filter << page

            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/page_queue_filter" ) ).
                collection.should == Set.new([page.persistent_hash])
        end

        it 'stores #url_queue_filter to disk' do
            subject.url_queue_filter << url

            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/url_queue_filter" ) ).
                collection.should == Set.new([url.persistent_hash])
        end

        it 'stores #browser_skip_states to disk' do
            stuff = 'stuff'
            subject.browser_skip_states << stuff

            subject.dump( dump_directory )

            set = Arachni::Support::LookUp::HashSet.new( hasher: :persistent_hash)
            set << stuff

            Marshal.load( IO.read( "#{dump_directory}/browser_skip_states" ) ).should == set
        end
    end

    describe '.load' do
        it 'loads #rpc from disk' do
            subject.dump( dump_directory )
            described_class.load( dump_directory ).rpc.should be_kind_of described_class::RPC
        end

        it 'loads #element_pre_check_filter from disk' do
            subject.element_pre_check_filter << element

            subject.dump( dump_directory )

            described_class.load( dump_directory ).element_pre_check_filter.
                collection.should == Set.new([element.coverage_hash])
        end

        it 'loads #page_queue_filter from disk' do
            subject.page_queue_filter << page

            subject.dump( dump_directory )

            described_class.load( dump_directory ).page_queue_filter.
                collection.should == Set.new([page.persistent_hash])
        end

        it 'loads #url_queue_filter from disk' do
            subject.url_queue_filter << url
            subject.url_queue_filter.should be_any

            subject.dump( dump_directory )

            described_class.load( dump_directory ).url_queue_filter.
                collection.should == Set.new([url.persistent_hash])
        end

        it 'loads #browser_skip_states from disk' do
            stuff = 'stuff'
            subject.browser_skip_states << stuff

            subject.dump( dump_directory )

            set = Arachni::Support::LookUp::HashSet.new( hasher: :persistent_hash)
            set << stuff
            described_class.load( dump_directory ).browser_skip_states.should == set
        end
    end

    describe '#clear' do
        %w(rpc element_pre_check_filter browser_skip_states page_queue_filter
            url_queue_filter).each do |method|
            it "clears ##{method}" do
                subject.send(method).should receive(:clear)
                subject.clear
            end
        end

        it 'sets #running to false' do
            subject.running = true
            subject.clear
            subject.should_not be_running
        end
    end
end
