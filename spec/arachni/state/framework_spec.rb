require 'spec_helper'

describe Arachni::State::Framework do
    after(:each) do
        FileUtils.rm_rf @dump_directory if @dump_directory
    end

    subject { described_class.new }
    before(:each) { subject.clear }

    let(:page) { Factory[:page] }
    let(:url) { page.url }
    let(:dump_directory) do
        @dump_directory = "#{Dir.tmpdir}/framework-#{Arachni::Utilities.generate_token}"
    end

    describe '#rpc' do
        it "returns an instance of #{described_class::RPC}" do
            subject.rpc.should be_kind_of described_class::RPC
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

    describe '#suspend' do
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
                it 'sets the #status to :suspending' do
                    subject.pause( :a_caller, false )
                    subject.status.should == :pausing
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

    describe '#sitemap' do
        it 'returns a Hash' do
            subject.sitemap.should be_kind_of Hash
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

    describe '#page_queue' do
        it "returns an instance of #{Arachni::Support::Database::Queue}" do
            subject.page_queue.should be_kind_of Arachni::Support::Database::Queue
        end
    end

    describe '#page_queue_filter' do
        it "returns an instance of #{Arachni::Support::LookUp::HashSet}" do
            subject.page_queue_filter.should be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#push_to_page_queue' do
        it 'pushes a page to the #page_queue' do
            subject.push_to_page_queue page
        end

        it 'increments #page_queue_total_size' do
            subject.page_queue_total_size.should == 0
            subject.push_to_page_queue page
            subject.page_queue_total_size.should == 1
        end

        it 'updates the sitemap' do
            subject.should receive(:add_page_to_sitemap).with(page)
            subject.push_to_page_queue page
        end

        it 'updates #page_queue_filter' do
            subject.push_to_page_queue page
            subject.page_queue_filter.should include page
        end
    end

    describe '#page_seen?' do
        context 'when a page has already been seen' do
            it 'returns true' do
                subject.push_to_page_queue page
                subject.page_seen?( page ).should be_true
            end
        end

        context 'when a page has not been seen' do
            it 'returns false' do
                subject.page_seen?( page ).should be_false
            end
        end
    end

    describe '#page_queue_total_size' do
        it 'defaults to 0' do
            subject.page_queue_total_size.should == 0
        end
    end

    describe '#url_queue' do
        it "returns an instance of #{Arachni::Support::Database::Queue}" do
            subject.url_queue.should be_kind_of Arachni::Support::Database::Queue
        end
    end

    describe '#url_queue_filter' do
        it "returns an instance of #{Arachni::Support::LookUp::HashSet}" do
            subject.url_queue_filter.should be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#url_queue_total_size' do
        it 'defaults to 0' do
            subject.url_queue_total_size.should == 0
        end
    end

    describe '#push_to_url_queue' do
        it 'pushes a page to the #page_queue' do
            subject.push_to_url_queue url
        end

        it 'increments #url_queue_total_size' do
            subject.url_queue_total_size.should == 0
            subject.push_to_url_queue url
            subject.url_queue_total_size.should == 1
        end

        it 'updates #url_queue_filter' do
            subject.push_to_url_queue url
            subject.url_queue_filter.should include url
        end
    end

    describe '#url_seen?' do
        context 'when a URL has already been seen' do
            it 'returns true' do
                subject.push_to_url_queue url
                subject.url_seen?( url ).should be_true
            end
        end

        context 'when a page has not been seen' do
            it 'returns false' do
                subject.url_seen?( url ).should be_false
            end
        end
    end

    describe '#add_page_to_sitemap' do
        it 'updates the sitemap with the given page' do
            subject.add_page_to_sitemap page
            subject.sitemap[page.url].should == page.code
        end
    end

    describe '#dump' do
        it 'stores #rpc to disk' do
            subject.dump( dump_directory )
            described_class::RPC.load( "#{dump_directory}/rpc" ).should be_kind_of described_class::RPC
        end

        it 'stores #sitemap to disk' do
            subject.sitemap[page.url] = page.code
            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/sitemap" ) ).should == {
                page.url => page.code
            }
        end

        it 'stores #page_queue to disk' do
            subject.page_queue.max_buffer_size = 1
            subject.push_to_page_queue page
            subject.push_to_page_queue page

            subject.page_queue.buffer.should include page
            subject.page_queue.disk.size.should == 1

            subject.dump( dump_directory )

            pages = []
            Dir["#{dump_directory}/page_queue/*"].each do |page_file|
                pages << Marshal.load( IO.read( page_file ) )
            end
            pages.should == [page, page]
        end

        it 'stores #page_queue_filter to disk' do
            subject.push_to_page_queue page

            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/page_queue_filter" ) ).
                collection.should == Set.new([page.persistent_hash])
        end

        it 'stores #page_queue_total_size to disk' do
            subject.push_to_page_queue page
            subject.push_to_page_queue page
            subject.page_queue_total_size.should == 2

            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/page_queue_total_size" ) ).should == 2
        end

        it 'stores #url_queue to disk' do
            subject.push_to_url_queue url
            subject.push_to_url_queue url

            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/url_queue" ) ).should == [url, url]
        end

        it 'stores #url_queue_filter to disk' do
            subject.push_to_url_queue url

            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/url_queue_filter" ) ).
                collection.should == Set.new([url.persistent_hash])
        end

        it 'stores #url_queue_total_size to disk' do
            subject.push_to_url_queue url
            subject.push_to_url_queue url
            subject.url_queue_total_size.should == 2

            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/url_queue_total_size" ) ).should == 2
        end

        it 'stores #browser_skip_states to disk' do
            stuff = 'stuff'
            subject.browser_skip_states << stuff

            subject.dump( dump_directory )

            set = Arachni::Support::LookUp::HashSet.new( hasher: :persistent_hash)
            set << stuff

            Marshal.load( IO.read( "#{dump_directory}/browser_skip_states" ) ).should == set
        end

        it 'stores #pause_signals to disk' do
            subject.pause_signals << :stuff

            subject.dump( dump_directory )

            Marshal.load( IO.read( "#{dump_directory}/pause_signals" ) ).should == Set.new([:stuff])
        end
    end

    describe '.load' do
        it 'loads #rpc from disk' do
            subject.dump( dump_directory )
            described_class.load( dump_directory ).rpc.should be_kind_of described_class::RPC
        end

        it 'loads #sitemap from disk' do
            subject.sitemap[page.url] = page.code
            subject.dump( dump_directory )

            described_class.load( dump_directory ).sitemap.should == subject.sitemap
        end

        it 'loads #page_queue from disk' do
            subject.page_queue.max_buffer_size = 1
            subject.push_to_page_queue page
            subject.push_to_page_queue page

            subject.dump( dump_directory )

            page_queue = described_class.load( dump_directory ).page_queue
            page_queue.size.should == 2
            page_queue.pop.should == page
            page_queue.pop.should == page
        end

        it 'loads #page_queue_filter from disk' do
            subject.push_to_page_queue page

            subject.dump( dump_directory )

            described_class.load( dump_directory ).page_queue_filter.
                collection.should == Set.new([page.persistent_hash])
        end

        it 'loads #page_queue_total_size from disk' do
            subject.push_to_page_queue page
            subject.push_to_page_queue page
            subject.page_queue_total_size.should == 2

            subject.dump( dump_directory )

            described_class.load( dump_directory ).page_queue_total_size.should == 2
        end

        it 'loads #url_queue from disk' do
            subject.push_to_url_queue url
            subject.push_to_url_queue url

            subject.dump( dump_directory )

            url_queue = described_class.load( dump_directory ).url_queue
            url_queue.size.should == 2
            url_queue.pop.should == url
            url_queue.pop.should == url
        end

        it 'loads #url_queue_filter from disk' do
            subject.push_to_url_queue url
            subject.url_queue_filter.should be_any

            subject.dump( dump_directory )

            described_class.load( dump_directory ).url_queue_filter.
                collection.should == Set.new([url.persistent_hash])
        end

        it 'loads #url_queue_total_size from disk' do
            subject.push_to_url_queue url
            subject.push_to_url_queue url
            subject.url_queue_total_size.should == 2

            subject.dump( dump_directory )

            described_class.load( dump_directory ).url_queue_total_size.should == 2
        end

        it 'loads #browser_skip_states from disk' do
            stuff = 'stuff'
            subject.browser_skip_states << stuff

            subject.dump( dump_directory )

            set = Arachni::Support::LookUp::HashSet.new( hasher: :persistent_hash)
            set << stuff
            described_class.load( dump_directory ).browser_skip_states.should == set
        end

        it 'loads #pause_signals from disk' do
            subject.pause_signals << :stuff

            subject.dump( dump_directory )

            described_class.load( dump_directory ).pause_signals.should == Set.new([:stuff])
        end
    end

    describe '#clear' do
        %w(rpc browser_skip_states sitemap page_queue page_queue_filter
            url_queue url_queue_filter pause_signals).each do |method|
            it "clears ##{method}" do
                subject.send(method).should receive(:clear)
                subject.clear
            end
        end

        it 'sets #page_queue_total_size to 0' do
            subject.push_to_page_queue page
            subject.page_queue_total_size.should == 1
            subject.clear
            subject.page_queue_total_size.should == 0
        end

        it 'sets #url_queue_total_size to 0' do
            subject.push_to_url_queue page.url
            subject.url_queue_total_size.should == 1
            subject.clear
            subject.url_queue_total_size.should == 0
        end

        it 'sets #running to false' do
            subject.running = true
            subject.clear
            subject.should_not be_running
        end
    end
end
