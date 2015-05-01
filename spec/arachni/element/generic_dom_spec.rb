require 'spec_helper'

describe Arachni::Element::GenericDOM do
    it_should_behave_like 'element'
    it_should_behave_like 'with_source'
    it_should_behave_like 'with_auditor'

    let(:url) { 'http://test.com/' }
    let(:element) do
        Arachni::Browser::ElementLocator.new(
            tag_name:   :input,
            attributes: element_attributes
        )
    end
    let(:element_attributes) do
        {
            'id'    => 'my-id',
            'class' => 'my-class'
        }
    end
    let(:transition_options) {{}}
    let(:transition) do
        Arachni::Page::DOM::Transition.new( element, :keypress, transition_options )
    end
    subject do
        described_class.new( url: url, transition: transition )
    end

    describe '#initialize' do
        it "sets #source form the #{Arachni::Browser::ElementLocator}" do
            subject.source.should == element.to_s
        end
    end

    describe '#transition' do
        it 'returns the associated transition' do
            subject.transition.should == transition
        end
    end

    describe '#event' do
        it 'returns the associated event' do
            subject.event.should == transition.event
        end

        it 'is aliased to #method' do
            subject.method.should == transition.event
        end
    end

    describe '#element' do
        it 'returns the associated element locator' do
            subject.element.should == transition.element
        end
    end

    describe '#attributes' do
        it 'returns the associated element attributes' do
            subject.attributes.should == transition.element.attributes
        end
    end

    describe '#name' do
        let(:element_attributes) do
            {
                'name' => 'my-name'
            }
        end

        it 'returns the element name from the its attributes' do
            subject.name.should == 'my-name'
        end

        context 'when an id is set instead of a name' do
            let(:element_attributes) do
                {
                    'id' => 'my-id'
                }
            end

            it 'returns the id' do
                subject.name.should == 'my-id'
            end
        end

        it 'is aliased to #affected_input_name' do
            subject.affected_input_name.should == subject.name
        end
    end

    describe '#value' do
        let(:transition_options) do
            {
                value: 'my-val'
            }
        end

        it 'returns the value for the element' do
            subject.value.should == 'my-val'
        end

        it 'is aliased to #affected_input_value' do
            subject.affected_input_value.should == subject.value
        end
    end

    describe '#type' do
        it 'returns the #element tag name' do
            subject.type.should == element.tag_name
        end
    end

    describe '#to_h' do
        it 'includes the #transition' do
            subject.to_h[:transition].should == transition.to_h.tap do |h|
                h[:element] = h[:element].to_h
            end
        end
    end
end
