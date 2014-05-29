require 'spec_helper'

class ObservableTest
    include Arachni::Mixins::Observable

    public :clear_observers

    advertise :my_event, :my_other_event

    def call( event, *args )
        send "call_#{event}", *args
    end

end

describe Arachni::Mixins::Observable do

    subject{ ObservableTest.new }

    describe '#<event>' do
        it 'adds an observer' do
            called = false
            subject.my_event { called = true }
            subject.call :my_event

            called.should be_true
        end

        it 'returns self' do
            subject.my_event { }.should == subject
        end

        context 'when no block is given' do
            it 'raises ArgumentError' do
                expect { subject.my_event }.to raise_error ArgumentError
            end
        end

        context 'when the observer expects arguments' do
            it 'forwards them' do
                received_args = nil
                sent_args     = [ 1, 2, 3]

                subject.my_other_event do |one, two, three|
                    received_args = [one, two, three]
                end
                subject.call :my_other_event, sent_args

                received_args.should == sent_args
            end
        end

        describe 'when the event does not exist' do
            it "raises #{NoMethodError}" do
                expect { subject.blah_event }.to raise_error NoMethodError
            end
        end
    end

    describe '#call_<event>' do
        it 'returns nil' do
            subject.my_event { }
            subject.call( :my_event ).should be_nil
        end
    end

    describe '#clear_observers' do
        it 'removes all observers' do
            called = false

            subject.my_event { called = true }
            subject.clear_observers

            subject.call :my_event

            called.should be_false

        end
    end

end
