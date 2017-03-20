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
            expect(subject.status_messages).to eq([message])
        end

        context 'by defaults' do
            it 'returns an empty array' do
                expect(subject.status_messages).to eq([])
            end
        end
    end

    describe '#set_status_message' do
        it 'sets the #status_messages to the given message' do
            message = 'Hey!'
            subject.set_status_message message
            subject.set_status_message message
            expect(subject.status_messages).to eq([message])
        end
    end

    describe '#add_status_message' do
        context 'when given a message of type' do
            context 'String' do
                it 'pushes it to #status_messages' do
                    message = 'Hey!'
                    subject.add_status_message message
                    subject.add_status_message message
                    expect(subject.status_messages).to eq([message, message])
                end
            end

            context 'Symbol' do
                context 'and it exists in #available_status_messages' do
                    it 'pushes the associated message to #status_messages' do
                        subject.add_status_message :suspending
                        expect(subject.status_messages).to eq([subject.available_status_messages[:suspending]])
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
                        expect(subject.status_messages).to eq([subject.available_status_messages[:snapshot_location] % location])
                    end
                end
            end
        end
    end

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        it 'includes #rpc statistics' do
            expect(statistics[:rpc]).to eq(subject.rpc.statistics)
        end

        it 'includes #audited_page_count' do
            subject.audited_page_count += 1
            expect(statistics[:audited_page_count]).to eq(subject.audited_page_count)
        end

        it 'includes amount of #browser_skip_states' do
            set = Arachni::Support::LookUp::HashSet.new
            set << 1 << 2 << 3
            subject.update_browser_skip_states( set )

            expect(statistics[:browser_states]).to eq(subject.browser_skip_states.size)
        end
    end

    describe '#page_queue_filter' do
        it "returns an instance of #{Arachni::Support::LookUp::HashSet}" do
            expect(subject.page_queue_filter).to be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#url_queue_filter' do
        it "returns an instance of #{Arachni::Support::LookUp::HashSet}" do
            expect(subject.url_queue_filter).to be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#rpc' do
        it "returns an instance of #{described_class::RPC}" do
            expect(subject.rpc).to be_kind_of described_class::RPC
        end
    end

    describe '#element_checked?' do
        context 'when an element has already been checked' do
            it 'returns true' do
                subject.element_pre_check_filter << element
                expect(subject.element_checked?( element )).to be_truthy
            end
        end

        context 'when an element has not been checked' do
            it 'returns false' do
                expect(subject.element_checked?( element )).to be_falsey
            end
        end
    end

    describe '#element_checked' do
        it 'marks an element as checked' do
            subject.element_checked element
            expect(subject.element_checked?( element )).to be_truthy
        end
    end

    describe '#page_seen?' do
        context 'when a page has already been seen' do
            it 'returns true' do
                subject.page_queue_filter << page
                expect(subject.page_seen?( page )).to be_truthy
            end
        end

        context 'when a page has not been seen' do
            it 'returns false' do
                expect(subject.page_seen?( page )).to be_falsey
            end
        end
    end

    describe '#page_seen' do
        context 'when the given page has been marked as seen' do
            it 'returns true' do
                subject.page_seen page
                expect(subject.page_seen?( page )).to be_truthy
            end
        end

        context 'when the given page has not been marked as seen' do
            it 'returns false' do
                expect(subject.page_seen?( page )).to be_falsey
            end
        end
    end

    describe '#url_seen?' do
        context 'when a URL has already been seen' do
            it 'returns true' do
                subject.url_queue_filter << url
                expect(subject.url_seen?( url )).to be_truthy
            end
        end

        context 'when a page has not been seen' do
            it 'returns false' do
                expect(subject.url_seen?( url )).to be_falsey
            end
        end
    end

    describe '#url_seen' do
        context 'when the given URL has been marked as seen' do
            it 'returns true' do
                subject.url_seen url
                expect(subject.url_seen?( url )).to be_truthy
            end
        end

        context 'when the given URL has not been marked as seen' do
            it 'returns false' do
                expect(subject.url_seen?( url )).to be_falsey
            end
        end
    end

    describe '#running=' do
        it 'sets #running' do
            expect(subject.running).to be_falsey

            subject.running = true
            expect(subject.running).to be_truthy
        end
    end

    describe '#running?' do
        context 'when #running is true' do
            it 'returns true' do
                subject.running = true
                expect(subject).to be_running
            end
        end

        context 'when #running is false' do
            it 'returns false' do
                subject.running = false
                expect(subject).not_to be_running
            end
        end
    end

    describe '#scanning?' do
        context 'when the status is set to :scanning' do
            it 'returns true' do
                subject.status = :scanning
                expect(subject).to be_scanning
            end
        end

        context 'when the status is not set to :scanning' do
            it 'returns false' do
                expect(subject).not_to be_scanning
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
                    expect(Time.now - time).to be > 1
                    t.join
                end

                it 'sets the #status to :suspended' do
                    t = Thread.new do
                        sleep 1
                        subject.suspended
                    end
                    subject.suspend
                    t.join

                    expect(subject.status).to eq(:suspended)
                end

                it 'sets the status message to :suspending' do
                    t = Thread.new do
                        sleep 1
                        subject.suspended
                    end
                    subject.suspend
                    t.join

                    expect(subject.status_messages).to eq(
                        [subject.available_status_messages[:suspending]]
                    )
                end

                it 'returns true' do
                    t = Thread.new do
                        sleep 1
                        subject.suspended
                    end
                    expect(subject.suspend).to be_truthy
                    t.join

                    expect(subject.status).to eq(:suspended)
                end
            end

            context 'when non-blocking' do
                it 'sets the #status to :suspending' do
                    subject.suspend( false )
                    expect(subject.status).to eq(:suspending)
                end

                it 'sets the status message to :suspending' do
                    subject.suspend( false )
                    expect(subject.status_messages).to eq(
                        [subject.available_status_messages[:suspending]]
                    )
                end

                it 'returns true' do
                    expect(subject.suspend( false )).to be_truthy
                end
            end

            context 'when already #suspending?' do
                it 'returns false' do
                    expect(subject.suspend( false )).to be_truthy
                    expect(subject).to be_suspending
                    expect(subject.suspend).to be_falsey
                end
            end

            context 'when already #suspended?' do
                it 'returns false' do
                    expect(subject.suspend( false )).to be_truthy
                    subject.suspended
                    expect(subject).to be_suspended

                    expect(subject.suspend).to be_falsey
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
            expect(subject.status).to eq(:suspended)
        end
    end

    describe '#suspended?' do
        context 'when #suspended' do
            it 'returns true' do
                subject.suspended
                expect(subject).to be_suspended
            end
        end

        context 'when not #suspended' do
            it 'returns false' do
                expect(subject).not_to be_suspended
            end
        end
    end

    describe '#suspending?' do
        before(:each) { subject.running = true }

        context 'while suspending' do
            it 'returns true' do
                subject.suspend( false )
                expect(subject).to be_suspending
            end
        end

        context 'while not suspending' do
            it 'returns false' do
                expect(subject).not_to be_suspending

                subject.suspend( false )
                subject.suspended
                expect(subject).not_to be_suspending
            end
        end
    end

    describe '#suspend?' do
        before(:each) { subject.running = true }

        context 'when a #suspend signal is in place' do
            it 'returns true' do
                subject.suspend( false )
                expect(subject).to be_suspend
            end
        end

        context 'when a #suspend signal is not in place' do
            it 'returns false' do
                expect(subject).not_to be_suspend

                subject.suspend( false )
                subject.suspended
                expect(subject).not_to be_suspend
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
                    expect(Time.now - time).to be > 1
                    t.join
                end

                it 'sets the #status to :aborted' do
                    t = Thread.new do
                        sleep 1
                        subject.aborted
                    end
                    subject.abort
                    t.join

                    expect(subject.status).to eq(:aborted)
                end

                it 'sets the status message to :aborting' do
                    t = Thread.new do
                        sleep 1
                        subject.aborted
                    end
                    subject.abort
                    t.join

                    expect(subject.status_messages).to eq(
                        [subject.available_status_messages[:aborting]]
                    )
                end

                it 'returns true' do
                    t = Thread.new do
                        sleep 1
                        subject.aborted
                    end
                    expect(subject.abort).to be_truthy
                    t.join

                    expect(subject.status).to eq(:aborted)
                end
            end

            context 'when non-blocking' do
                it 'sets the #status to :aborting' do
                    subject.abort( false )
                    expect(subject.status).to eq(:aborting)
                end

                it 'sets the status message to :aborting' do
                    subject.abort( false )
                    expect(subject.status_messages).to eq(
                        [subject.available_status_messages[:aborting]]
                    )
                end

                it 'returns true' do
                    expect(subject.abort( false )).to be_truthy
                end
            end

            context 'when already #aborting?' do
                it 'returns false' do
                    expect(subject.abort( false )).to be_truthy
                    expect(subject).to be_aborting
                    expect(subject.abort).to be_falsey
                end
            end

            context 'when already #aborted?' do
                it 'returns false' do
                    expect(subject.abort( false )).to be_truthy
                    subject.aborted
                    expect(subject).to be_aborted

                    expect(subject.abort).to be_falsey
                end
            end
        end

        context 'when not #running?' do
            it "raises #{described_class::Error::StateNotAbortable}" do
                expect{ subject.abort }.to raise_error described_class::Error::StateNotAbortable
            end
        end
    end

    describe '#done?' do
        context 'when #status is :done' do
            it 'returns true' do
                subject.status = :done
                expect(subject).to be_done
            end
        end

        context 'when not done' do
            it 'returns false' do
                expect(subject).not_to be_done
            end
        end
    end

    describe '#aborted' do
        it 'sets the #status to :aborted' do
            subject.aborted
            expect(subject.status).to eq(:aborted)
        end
    end

    describe '#aborted?' do
        context 'when #aborted' do
            it 'returns true' do
                subject.aborted
                expect(subject).to be_aborted
            end
        end

        context 'when not #aborted' do
            it 'returns false' do
                expect(subject).not_to be_aborted
            end
        end
    end

    describe '#aborting?' do
        before(:each) { subject.running = true }

        context 'while aborting' do
            it 'returns true' do
                subject.abort( false )
                expect(subject).to be_aborting
            end
        end

        context 'while not aborting' do
            it 'returns false' do
                expect(subject).not_to be_aborting

                subject.abort( false )
                subject.aborted
                expect(subject).not_to be_aborting
            end
        end
    end

    describe '#abort?' do
        before(:each) { subject.running = true }

        context 'when a #abort signal is in place' do
            it 'returns true' do
                subject.abort( false )
                expect(subject).to be_abort
            end
        end

        context 'when a #abort signal is not in place' do
            it 'returns false' do
                expect(subject).not_to be_abort

                subject.abort( false )
                subject.aborted
                expect(subject).not_to be_abort
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
                    expect(Time.now - time).to be > 1
                    t.join
                end

                it 'sets the #status to :paused' do
                    t = Thread.new do
                        sleep 1
                        subject.paused
                    end
                    subject.pause :a_caller
                    t.join

                    expect(subject.status).to eq(:paused)
                end

                it 'returns true' do
                    t = Thread.new do
                        sleep 1
                        subject.paused
                    end
                    expect(subject.pause( :a_caller )).to be_truthy
                    t.join

                    expect(subject.status).to eq(:paused)
                end
            end

            context 'when non-blocking' do
                it 'sets the #status to :pausing' do
                    subject.pause( :a_caller, false )
                    expect(subject.status).to eq(:pausing)
                end

                it 'returns true' do
                    expect(subject.pause( :a_caller, false )).to be_truthy
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
                expect(subject.status).to eq(:paused)
                expect(Time.now - time).to be < 1
                t.join
            end
        end
    end

    describe '#paused' do
        it 'sets the #status to :paused' do
            subject.paused
            expect(subject.status).to eq(:paused)
        end
    end

    describe '#pausing?' do
        before(:each) { subject.running = true }

        context 'while pausing' do
            it 'returns true' do
                subject.pause( :caller, false )
                expect(subject).to be_pausing
            end
        end

        context 'while not pausing' do
            it 'returns false' do
                expect(subject).not_to be_pausing

                subject.pause( :caller, false )
                subject.paused
                expect(subject).not_to be_pausing
            end
        end
    end

    describe '#pause?' do
        context 'when a #pause signal is in place' do
            it 'returns true' do
                subject.pause( :caller, false )
                expect(subject).to be_pause
            end
        end

        context 'when a #pause signal is not in place' do
            it 'returns false' do
                expect(subject).not_to be_pause

                subject.pause( :caller, false )
                subject.paused
                subject.resume( :caller )
                expect(subject).not_to be_pause
            end
        end
    end

    describe '#resume' do
        before(:each) { subject.running = true }

        it 'removes a #pause signal' do
            subject.pause( :caller, false )
            expect(subject.pause_signals).to include :caller

            subject.resume( :caller )

            expect(subject.pause_signals).not_to include :caller
            expect(subject).not_to be_paused
        end

        it 'operates on a per-caller basis' do
            subject.pause( :caller, false )
            subject.pause( :caller, false )
            subject.pause( :caller, false )
            subject.paused
            subject.pause( :caller2, false )

            subject.resume( :caller )
            expect(subject).to be_paused

            subject.resume( :caller2 )
            expect(subject).not_to be_paused
        end

        it 'restores the previous #status' do
            subject.status = :my_status

            subject.pause( :caller, false )
            subject.paused
            expect(subject.status).to be :paused

            subject.resume( :caller )
            expect(subject.status).to be :my_status
        end

        context 'when called before a #pause signal has been sent' do
            it '#pause? returns false' do
                subject.pause( :caller, false )
                subject.resume( :caller )
                expect(subject).not_to be_pause
            end

            it '#paused? returns false' do
                subject.pause( :caller, false )
                subject.resume( :caller )
                expect(subject).not_to be_paused
            end
        end

        context 'when there are no more signals' do
            it 'returns true' do
                subject.pause( :caller, false )
                subject.paused

                expect(subject.resume( :caller )).to be_truthy
            end
        end

        context 'when there are more signals' do
            it 'returns false' do
                subject.pause( :caller, false )
                subject.pause( :caller2, false )
                subject.paused

                expect(subject.resume( :caller )).to be_falsey
            end
        end
    end

    describe '#browser_skip_states' do
        it "returns a #{Arachni::Support::LookUp::HashSet}" do
            expect(subject.browser_skip_states).to be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#update_browser_skip_states' do
        it 'updates #browser_skip_states' do
            expect(subject.browser_skip_states).to be_empty

            set = Arachni::Support::LookUp::HashSet.new
            set << 1 << 2 << 3
            subject.update_browser_skip_states( set )
            expect(subject.browser_skip_states).to eq(set)
        end
    end

    describe '#dump' do
        it 'stores #rpc to disk' do
            subject.dump( dump_directory )
            expect(described_class::RPC.load( "#{dump_directory}/rpc" )).to be_kind_of described_class::RPC
        end

        it 'stores #page_queue_filter to disk' do
            subject.page_queue_filter << page

            subject.dump( dump_directory )

            expect(Marshal.load( IO.read( "#{dump_directory}/page_queue_filter" ) ).
                collection).to eq(Set.new([page.persistent_hash]))
        end

        it 'stores #url_queue_filter to disk' do
            subject.url_queue_filter << url

            subject.dump( dump_directory )

            expect(Marshal.load( IO.read( "#{dump_directory}/url_queue_filter" ) ).
                collection).to eq(Set.new([url.persistent_hash]))
        end

        it 'stores #browser_skip_states to disk' do
            stuff = 'stuff'
            subject.browser_skip_states << stuff

            subject.dump( dump_directory )

            set = Arachni::Support::LookUp::HashSet.new( hasher: :persistent_hash)
            set << stuff

            expect(Marshal.load( IO.read( "#{dump_directory}/browser_skip_states" ) )).to eq(set)
        end
    end

    describe '.load' do
        it 'loads #rpc from disk' do
            subject.dump( dump_directory )
            expect(described_class.load( dump_directory ).rpc).to be_kind_of described_class::RPC
        end

        it 'loads #element_pre_check_filter from disk' do
            subject.element_pre_check_filter << element

            subject.dump( dump_directory )

            expect(described_class.load( dump_directory ).element_pre_check_filter.
                collection).to eq(Set.new([element.coverage_hash]))
        end

        it 'loads #page_queue_filter from disk' do
            subject.page_queue_filter << page

            subject.dump( dump_directory )

            expect(described_class.load( dump_directory ).page_queue_filter.
                collection).to eq(Set.new([page.persistent_hash]))
        end

        it 'loads #url_queue_filter from disk' do
            subject.url_queue_filter << url
            expect(subject.url_queue_filter).to be_any

            subject.dump( dump_directory )

            expect(described_class.load( dump_directory ).url_queue_filter.
                collection).to eq(Set.new([url.persistent_hash]))
        end

        it 'loads #browser_skip_states from disk' do
            stuff = 'stuff'
            subject.browser_skip_states << stuff

            subject.dump( dump_directory )

            set = Arachni::Support::LookUp::HashSet.new( hasher: :persistent_hash)
            set << stuff
            expect(described_class.load( dump_directory ).browser_skip_states).to eq(set)
        end
    end

    describe '#clear' do
        %w(rpc element_pre_check_filter browser_skip_states page_queue_filter
            url_queue_filter).each do |method|
            it "clears ##{method}" do
                expect(subject.send(method)).to receive(:clear)
                subject.clear
            end
        end

        it 'sets #running to false' do
            subject.running = true
            subject.clear
            expect(subject).not_to be_running
        end
    end
end
