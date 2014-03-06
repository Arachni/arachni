require 'spec_helper'

describe Arachni::Page::DOM::Transition do
    subject { Factory[:transition] }
    let(:empty_transition) { Factory[:empty_transition] }
    let(:running_transition) { Factory[:running_transition] }
    let(:completed_transition) { Factory[:completed_transition] }

    after :each do
        @browser.shutdown if @browser
    end
    
    describe '#initialize' do
        context 'when given options' do
            it 'uses them to configure the attributes' do
                t = described_class.new( page: :load )
                t.element.should == :page
                t.event.should == :load
            end

            it 'marks it as running' do
                described_class.new( page: :load ).should be_running
            end
        end

        context 'when given extra options' do
            it 'stores them' do
                options = { more: :stuff }

                t = described_class.new( { page: :load }, options )
                t.options.should == options
            end
        end

        context 'when passed a block' do
            it 'calls the block' do
                called = false
                described_class.new page: :load do
                    called = true
                end
                called.should be_true
            end

            it 'marks the transition as finished' do
                called = false
                t = described_class.new page: :load do
                    called = true
                    sleep 1
                end

                called.should be_true
                t.time.should > 1
                t.should be_completed
                t.should_not be_running
            end
        end
    end

    describe '#start' do
        it 'configures the attributes' do
            t = empty_transition.start( page: :load )
            t.element.should == :page
            t.event.should == :load
        end

        it 'converts the event to a symbol' do
            empty_transition.start( page: 'load' ).event.should == :load
        end

        it 'marks it as running' do
            empty_transition.start( page: :load ).should be_running
        end

        it 'returns self' do
            empty_transition.start( page: :load ).should be empty_transition
        end

        context 'when given extra options' do
            it 'stores them' do
                options = { more: :stuff }

                t = empty_transition.start( { page: :load }, options )
                t.options.should == options
            end
        end

        context 'when passed a block' do
            it 'calls the block' do
                called = false
                empty_transition.start page: :load do
                    called = true
                end
                called.should be_true
            end

            it 'marks the transition as finished' do
                called = false
                t = empty_transition.start page: :load do
                    called = true
                    sleep 1
                end

                called.should be_true
                t.time.should > 1
                t.should be_completed
                t.should_not be_running
            end

            it 'returns self' do
                empty_transition.start( page: :load ){}.should be empty_transition
            end
        end

        context 'when the element is' do
            context String do
                it 'assigns it to #element' do
                    empty_transition.start '<form>' => :load
                    empty_transition.element.should == '<form>'

                end
            end
            context Symbol do
                it 'assigns it to #element' do
                    empty_transition.start page: :load
                    empty_transition.element.should == :page
                end
            end
            context 'other' do
                it "raises #{described_class::Error::InvalidElement}" do
                    expect do
                        empty_transition.start( 0 => :load )
                    end.to raise_error described_class::Error::InvalidElement
                end
            end
        end

        context 'when the job is running' do
            it "raises #{described_class::Error::Running}" do
                expect do
                    running_transition.start( page: :load )
                end.to raise_error described_class::Error::Running
            end
        end

        context 'when the job is completed' do
            it "raises #{described_class::Error::Completed}" do
                expect do
                    completed_transition.start( page: :load )
                end.to raise_error described_class::Error::Completed
            end
        end
    end

    describe '#complete' do
        it 'sets the #time' do
            running = Factory[:running_transition]
            sleep 1
            running.complete.time.should > 1
        end

        it 'marks it as completed' do
            running_transition.complete.should be_completed
        end

        it 'returns self' do
            running_transition.complete.should be running_transition
        end

        context 'when the job is not running' do
            it "raises #{described_class::Error::NotRunning}" do
                expect do
                    empty_transition.complete
                end.to raise_error described_class::Error::NotRunning
            end
        end

        context 'when the job is completed' do
            it "raises #{described_class::Error::Completed}" do
                expect do
                    completed_transition.complete
                end.to raise_error described_class::Error::Completed
            end
        end
    end

    describe '#depth' do
        context 'when the event is' do
            context :request do
                it 'returns 0' do
                    empty_transition.start( 'http://test/' => :request ).depth.should == 0
                end
            end

            context 'other' do
                it 'returns 1' do
                    empty_transition.start( stuff: :blah ).depth.should == 1
                end
            end
        end
    end

    describe '#element' do
        it 'returns the element associated with the transition' do
            subject.element.should == :page
        end

        context 'when the transition has not been initialized with any arguments' do
            it 'returns nil' do
                empty_transition.element.should be_nil
            end
        end
    end

    describe '#event' do
        it 'returns the event associated with the transition' do
            subject.event.should == :load
        end

        context 'when the transition has not been initialized with any arguments' do
            it 'returns nil' do
                empty_transition.event.should be_nil
            end
        end
    end

    describe '#options' do
        it 'returns any extra options' do
            subject.options.should == { extra: :options }
        end

        context 'when the transition has not been initialized with any arguments' do
            it 'returns an empty hash' do
                empty_transition.options.should == {}
            end
        end
    end

    describe '#time' do
        context 'when the transition has not been initialized with any arguments' do
            it 'returns nil' do
                empty_transition.time.should be_nil
            end
        end

        context 'when the transition is running' do
            it 'returns nil' do
                running_transition.should be_running
                running_transition.time.should be_nil
            end
        end

        context 'when the transition has completed' do
            it 'returns the time it took for the transition' do
                completed_transition.should_not be_running
                completed_transition.time.should > 0
            end
        end
    end

    describe '#play' do
        let(:url) do
            Arachni::Utilities.normalize_url( web_server_url_for( :browser ) ) + 'trigger_events'
        end

        before :each do
            @browser = Arachni::Browser.new
            @browser.load( url ).start_capture
        end

        context 'when the transition is playable' do
            it 'plays it' do
                pages_should_not_have_form_with_input [@browser.to_page], 'by-ajax'

                transition = described_class.new( '<div id="my-div" onclick="addForm();">' => :click )
                transition.complete.play( @browser ).should == transition

                pages_should_have_form_with_input [@browser.to_page], 'by-ajax'
            end

            it 'returns the new transition' do
                url = Arachni::Utilities.normalize_url( web_server_url_for( :browser ) )

                @browser.load( "#{url}/trigger_events" ).start_capture

                pages_should_not_have_form_with_input [@browser.to_page], 'by-ajax'

                transition = described_class.new( '<div id="my-div">' => :onclick )
                transition.complete.play( @browser ).should ==
                    described_class.new( '<div id="my-div" onclick="addForm();">' => :click )

                pages_should_have_form_with_input [@browser.to_page], 'by-ajax'
            end
        end

        context 'when the transition could not be played' do
            it 'returns nil' do
                described_class.new( '<div id="my-diva">' => :click ).
                    complete.play( @browser ).should be_nil
            end
        end

        context 'when the transition is not playable' do
            it "raises #{described_class::Error::NotPlayable}" do
                expect do
                    transition = described_class.new( '<div id="my-div">' => :load )
                    transition.playable?.should be_false
                    transition.complete.play( @browser ).should be_nil
                end.to raise_error described_class::Error::NotPlayable
            end
        end
    end

    describe '#running?' do
        context 'when the transition' do
            context 'is in progress' do
                it 'returns true' do
                    running_transition.running?.should be_true
                end
            end

            context 'has completed' do
                it 'returns false' do
                    completed_transition.running?.should be_false
                end
            end

            context 'is not progress' do
                it 'returns false' do
                    empty_transition.running?.should be_false
                end
            end
        end
    end

    describe '#completed?' do
        context 'when the transition' do
            context 'has completed' do
                it 'returns true' do
                    completed_transition.completed?.should be_true
                end
            end

            context 'is in progress' do
                it 'returns false' do
                    running_transition.completed?.should be_false
                end
            end

            context 'is not progress' do
                it 'returns false' do
                    empty_transition.completed?.should be_false
                end
            end
        end
    end

    describe '#to_hash' do
        it 'returns a hash representation of the transition' do
            hash = completed_transition.to_hash
            hash.delete(:time).should be_kind_of Float
            hash.should == {
                element: :page,
                event:   :load,
                options: {
                    extra: :options
                }
            }

        end
    end

    describe '#to_s' do
        it 'returns a string representation of the transition' do
            completed_transition.to_s.should ==
                "'#{completed_transition.event}' on: #{completed_transition.element}"
        end
    end

    describe '#dup' do
        it 'returns a copy of the transition' do
            subject.dup.should == subject
        end
    end

    describe '#==' do
        context 'when 2 transitions are identical' do
            it 'returns true' do
                args = [{ page: :load }, { extra: :options }]
                described_class.new( *args ).should == described_class.new( *args )
            end
        end

        context 'when 2 transitions are different' do
            it 'returns false' do
                args  = [{ page: :load }, { extra: :options }]
                args1 = [{ page: :load1 }, { extra: :options }]
                args2 = [{ page: :load }, { extra: :options1 }]
                args3 = [{ page1: :load }, { extra: :options }]
                args4 = [{ page: :load }, { extra1: :options }]

                described_class.new( *args ).should_not == described_class.new( *args1 )
                described_class.new( *args ).should_not == described_class.new( *args2 )
                described_class.new( *args ).should_not == described_class.new( *args3 )
                described_class.new( *args ).should_not == described_class.new( *args4 )
            end
        end
    end

    describe '#hash' do
        context 'when 2 transitions are identical' do
            it 'returns the same value' do
                args = [{ page: :load }, { extra: :options }]
                described_class.new( *args ).hash.should == described_class.new( *args ).hash
            end
        end

        context 'when 2 transitions are different' do
            it 'returns the same value' do
                args  = [{ page: :load }, { extra: :options }]
                args1 = [{ page: :load1 }, { extra: :options }]
                args2 = [{ page: :load }, { extra: :options1 }]
                args3 = [{ page1: :load }, { extra: :options }]
                args4 = [{ page: :load }, { extra1: :options }]

                described_class.new( *args ).hash.should_not == described_class.new( *args1 ).hash
                described_class.new( *args ).hash.should_not == described_class.new( *args2 ).hash
                described_class.new( *args ).hash.should_not == described_class.new( *args3 ).hash
                described_class.new( *args ).hash.should_not == described_class.new( *args4 ).hash
            end
        end
    end

end
