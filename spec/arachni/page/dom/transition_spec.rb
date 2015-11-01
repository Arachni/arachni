require 'spec_helper'

describe Arachni::Page::DOM::Transition do
    subject { Factory[:transition] }
    let(:empty_transition) { Factory[:empty_transition] }
    let(:running_transition) { Factory[:running_transition] }
    let(:completed_transition) { Factory[:completed_transition] }

    after :each do
        @browser.shutdown if @browser
        @browser = nil
    end

    it "supports #{Arachni::RPC::Serializer}" do
        expect(subject).to eq(Arachni::RPC::Serializer.deep_clone( subject ))
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        %w(element event options time).each do |attribute|
            it "includes '#{attribute}'" do
                expect(data[attribute]).to eq(subject.send( attribute ))
            end
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        %w(element event options time).each do |attribute|
            it "restores '#{attribute}'" do
                expect(restored.send( attribute )).to eq(subject.send( attribute ))
            end
        end

        context 'when the element is a' do
            context 'Symbol' do
                it 'restores it' do
                    original = described_class.new( :page, :load )
                    data     = Arachni::RPC::Serializer.rpc_data( original )
                    restored = described_class.from_rpc_data( data )

                    expect(restored.element).to eq(original.element)
                end
            end

            context 'Arachni::Browser::ElementLocator' do
                it 'restores it' do
                    element = Arachni::Browser::ElementLocator.from_html(
                        '<div id="my-div" onclick="addForm();">'
                    )

                    original = described_class.new( element, :click )
                    data     = Arachni::RPC::Serializer.rpc_data( original )
                    restored = described_class.from_rpc_data( data )

                    expect(restored.element).to eq(original.element)
                end
            end
        end
    end

    describe '#initialize' do
        context 'when given options' do
            it 'uses them to configure the attributes' do
                t = described_class.new( :page, :load )
                expect(t.element).to eq(:page)
                expect(t.event).to eq(:load)
            end

            it 'marks it as running' do
                expect(described_class.new( :page, :load )).to be_running
            end
        end

        context 'when given extra options' do
            it 'stores them' do
                options = { more: :stuff }

                t = described_class.new( :page, :load, options )
                expect(t.options).to eq(options)
            end
        end

        context 'when passed a block' do
            it 'calls the block' do
                called = false
                described_class.new :page, :load do
                    called = true
                end
                expect(called).to be_truthy
            end

            it 'marks the transition as finished' do
                called = false
                t = described_class.new :page, :load do
                    called = true
                    sleep 1.1
                end

                expect(called).to be_truthy
                expect(t.time).to be > 1
                expect(t).to be_completed
                expect(t).not_to be_running
            end
        end
    end

    describe '#start' do
        it 'configures the attributes' do
            t = empty_transition.start( :page, :load )
            expect(t.element).to eq(:page)
            expect(t.event).to eq(:load)
        end

        it 'converts the event to a symbol' do
            expect(empty_transition.start( :page, 'load' ).event).to eq(:load)
        end

        it 'marks it as running' do
            expect(empty_transition.start( :page, :load )).to be_running
        end

        it 'returns self' do
            expect(empty_transition.start( :page, :load )).to be empty_transition
        end

        context 'when given extra options' do
            it 'stores them' do
                options = { more: :stuff }

                t = empty_transition.start( :page, :load, options )
                expect(t.options).to eq(options)
            end
        end

        context 'when passed a block' do
            it 'calls the block' do
                called = false
                empty_transition.start :page, :load do
                    called = true
                end
                expect(called).to be_truthy
            end

            it 'marks the transition as finished' do
                called = false
                t = empty_transition.start :page, :load do
                    called = true
                    sleep 1.1
                end

                expect(called).to be_truthy
                expect(t.time).to be > 1
                expect(t).to be_completed
                expect(t).not_to be_running
            end

            it 'returns self' do
                expect(empty_transition.start( :page, :load ){}).to be empty_transition
            end
        end

        context 'when the element is' do
            context 'String' do
                it 'assigns it to #element' do
                    empty_transition.start 'http://test.com/stuff', :request
                    expect(empty_transition.element).to eq('http://test.com/stuff')

                end
            end
            context 'Symbol' do
                it 'assigns it to #element' do
                    empty_transition.start :page, :load
                    expect(empty_transition.element).to eq(:page)
                end
            end
            context 'other' do
                it "raises #{described_class::Error::InvalidElement}" do
                    expect do
                        empty_transition.start( 0, :load )
                    end.to raise_error described_class::Error::InvalidElement
                end
            end
        end

        context 'when the job is running' do
            it "raises #{described_class::Error::Running}" do
                expect do
                    running_transition.start( :page, :load )
                end.to raise_error described_class::Error::Running
            end
        end

        context 'when the job is completed' do
            it "raises #{described_class::Error::Completed}" do
                expect do
                    completed_transition.start( :page, :load )
                end.to raise_error described_class::Error::Completed
            end
        end
    end

    describe '#complete' do
        it 'sets the #time' do
            running = Factory[:running_transition]
            sleep 1.1
            expect(running.complete.time).to be > 1
        end

        it 'marks it as completed' do
            expect(running_transition.complete).to be_completed
        end

        it 'returns self' do
            expect(running_transition.complete).to be running_transition
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
            context ':request' do
                it 'returns 0' do
                    expect(empty_transition.start( 'http://test/', :request ).depth).to eq(0)
                end
            end

            context 'other' do
                it 'returns 1' do
                    expect(empty_transition.start( :stuff, :blah ).depth).to eq(1)
                end
            end
        end
    end

    describe '#element' do
        it 'returns the element associated with the transition' do
            expect(subject.element).to eq(:page)
        end

        context 'when the transition has not been initialized with any arguments' do
            it 'returns nil' do
                expect(empty_transition.element).to be_nil
            end
        end
    end

    describe '#event' do
        it 'returns the event associated with the transition' do
            expect(subject.event).to eq(:load)
        end

        context 'when the transition has not been initialized with any arguments' do
            it 'returns nil' do
                expect(empty_transition.event).to be_nil
            end
        end
    end

    describe '#options' do
        it 'returns any extra options' do
            expect(subject.options).to be_any
        end

        context 'when the transition has not been initialized with any arguments' do
            it 'returns an empty hash' do
                expect(empty_transition.options).to eq({})
            end
        end
    end

    describe '#time' do
        context 'when the transition has not been initialized with any arguments' do
            it 'returns nil' do
                expect(empty_transition.time).to be_nil
            end
        end

        context 'when the transition is running' do
            it 'returns nil' do
                expect(running_transition).to be_running
                expect(running_transition.time).to be_nil
            end
        end

        context 'when the transition has completed' do
            it 'returns the time it took for the transition' do
                expect(empty_transition).not_to be_running

                t = empty_transition.start :page, :load do
                    sleep 1.1
                end

                expect(t.time).to be > 1
                expect(t).to be_completed
                expect(t).not_to be_running
            end
        end
    end

    describe '#time=' do
        it 'sets #time' do
            completed_transition.time = 1.2
            expect(completed_transition.time).to eq(1.2)
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

                element = Arachni::Browser::ElementLocator.from_html(
                    '<div id="my-div" onclick="addForm();">'
                )
                transition = described_class.new( element, :click )
                expect(transition.complete.play( @browser )).to eq(transition)

                pages_should_have_form_with_input [@browser.to_page], 'by-ajax'
            end

            it 'returns the new transition' do
                url = Arachni::Utilities.normalize_url( web_server_url_for( :browser ) )

                @browser.load( "#{url}/trigger_events" ).start_capture

                pages_should_not_have_form_with_input [@browser.to_page], 'by-ajax'

                element = Arachni::Browser::ElementLocator.from_html(
                    '<div id="my-div">'
                )
                transition = described_class.new( element, :onclick )
                expect(transition.complete.play( @browser )).to eq(
                    described_class.new( element, :click )
                )

                pages_should_have_form_with_input [@browser.to_page], 'by-ajax'
            end
        end

        context 'when the transition could not be played' do
            it 'returns nil' do
                element = Arachni::Browser::ElementLocator.from_html(
                    '<div id="my-diva">'
                )
                expect(described_class.new( element, :click ).
                    complete.play( @browser )).to be_nil
            end
        end

        context 'when the transition is not playable' do
            it "raises #{described_class::Error::NotPlayable}" do
                transition = described_class.new( 'http://test/', :request )

                expect do
                    transition.complete.play( @browser )
                end.to raise_error described_class::Error::NotPlayable
            end
        end
    end

    describe '#running?' do
        context 'when the transition' do
            context 'is in progress' do
                it 'returns true' do
                    expect(running_transition.running?).to be_truthy
                end
            end

            context 'has completed' do
                it 'returns false' do
                    expect(completed_transition.running?).to be_falsey
                end
            end

            context 'is not progress' do
                it 'returns false' do
                    expect(empty_transition.running?).to be_falsey
                end
            end
        end
    end

    describe '#completed?' do
        context 'when the transition' do
            context 'has completed' do
                it 'returns true' do
                    expect(completed_transition.completed?).to be_truthy
                end
            end

            context 'is in progress' do
                it 'returns false' do
                    expect(running_transition.completed?).to be_falsey
                end
            end

            context 'is not progress' do
                it 'returns false' do
                    expect(empty_transition.completed?).to be_falsey
                end
            end
        end
    end

    describe '#to_hash' do
        it 'returns a hash representation of the transition' do
            hash = completed_transition.to_hash
            expect(hash.delete(:time)).to be_kind_of Float
            expect(hash).to eq({
                element: :page,
                event:   :load,
                options: completed_transition.options
            })
        end

        context "when #element is an #{Arachni::Browser::ElementLocator}" do
            it 'converts it to a hash as well' do
                element = Arachni::Browser::ElementLocator.from_html(
                    '<div id="my-div" onclick="addForm();">'
                )

                expect(described_class.new( element, :load ).to_hash).to eq({
                    element: element.to_h,
                    event:   :load,
                    options:  {},
                    time:     nil
                })
            end
        end
    end

    describe '#to_s' do
        it 'returns a string representation of the transition' do
            expect(completed_transition.to_s).to eq(
                "[#{completed_transition.time.to_f}s] " <<
                    "'#{completed_transition.event}' on:" <<
                    " #{completed_transition.element}"
            )
        end
    end

    describe '#dup' do
        it 'returns a copy of the transition' do
            expect(subject.dup).to eq(subject)
        end
    end

    describe '#==' do
        context 'when 2 transitions are identical' do
            it 'returns true' do
                args = [:page, :load, { extra: :options }]
                expect(described_class.new( *args )).to eq(described_class.new( *args ))
            end
        end

        context 'when 2 transitions are different' do
            it 'returns false' do
                args  = [:page, :load, { extra: :options }]
                args1 = [:page, :load1 , { extra: :options }]
                args2 = [:page, :load, { extra: :options1 }]
                args3 = [:page1, :load, { extra: :options }]
                args4 = [:page, :load, { extra1: :options }]

                expect(described_class.new( *args )).not_to eq(described_class.new( *args1 ))
                expect(described_class.new( *args )).not_to eq(described_class.new( *args2 ))
                expect(described_class.new( *args )).not_to eq(described_class.new( *args3 ))
                expect(described_class.new( *args )).not_to eq(described_class.new( *args4 ))
            end
        end
    end

    describe '#hash' do
        context 'when 2 transitions are identical' do
            it 'returns the same value' do
                args = [:page, :load, { extra: :options }]
                expect(described_class.new( *args ).hash).to eq(described_class.new( *args ).hash)
            end
        end

        context 'when 2 transitions are different' do
            it 'returns the same value' do
                args  = [:page, :load, { extra: :options }]
                args1 = [:page, :load1 , { extra: :options }]
                args2 = [:page, :load, { extra: :options1 }]
                args3 = [:page1, :load, { extra: :options }]
                args4 = [:page, :load, { extra1: :options }]

                expect(described_class.new( *args ).hash).not_to eq(described_class.new( *args1 ).hash)
                expect(described_class.new( *args ).hash).not_to eq(described_class.new( *args2 ).hash)
                expect(described_class.new( *args ).hash).not_to eq(described_class.new( *args3 ).hash)
                expect(described_class.new( *args ).hash).not_to eq(described_class.new( *args4 ).hash)
            end
        end
    end

end
