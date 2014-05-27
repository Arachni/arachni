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

    describe '#on_<event>' do
        it 'adds an observer' do
            called = false
            subject.on_my_event { called = true }
            subject.call :my_event

            called.should be_true
        end

        context 'when the observer expects arguments' do
            it 'forwards them' do
                received_args = nil
                sent_args     = [ 1, 2, 3]

                subject.on_my_other_event do |one, two, three|
                    received_args = [one, two, three]
                end
                subject.call :my_other_event, sent_args

                received_args.should == sent_args
            end
        end

        describe 'when the event does not exist' do
            it "raises #{NoMethodError}" do
                expect { subject.on_blah_event }.to raise_error NoMethodError
            end
        end
    end

    describe '#clear_observers' do
        it 'removes all observers' do
            called = false

            subject.on_my_event { called = true }
            subject.clear_observers

            subject.call :my_event

            called.should be_false

        end
    end

end
