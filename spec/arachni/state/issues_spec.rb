require 'spec_helper'

describe Arachni::State::Issues do

    subject { described_class.new }
    let(:issue) { Factory[:issue] }

    describe '#<<' do
        it 'registers an array of issues' do
            subject << issue
            subject.any?.should be_true
        end

        context 'when an issue was discovered by manipulating an input' do
            it 'does not register redundant issues' do
                i = issue.deep_clone
                i.vector.affected_input_name = 'some input'
                20.times { subject << i }

                subject.size.should == 1
            end
        end

        context 'when an issue was not discovered by manipulating an input' do
            it 'registers it multiple times' do
                20.times { subject << issue }
                subject.flatten.size.should == 20
            end
        end
    end

    describe '#on_new' do
        it 'registers callbacks to be called on new issue' do
            callback_called = 0
            subject.on_new { callback_called += 1 }
            10.times { subject << Factory[:active_issue] }
            callback_called.should == 1
        end
    end

    describe '#on_new_pre_deduplication' do
        it 'registers callbacks to be called on #<<' do
            callback_called = 0
            subject.on_new_pre_deduplication { callback_called += 1 }
            10.times { subject << issue }
            callback_called.should == 10
        end
    end

    describe '#do_not_store' do
        it 'does not store results' do
            subject.do_not_store
            subject << issue
            subject.empty?.should be_true
        end
    end

    describe '#all' do
        it 'returns all issues' do
            subject << issue
            subject.all.should == [issue]
        end

        it 'groups issues as variations' do
            20.times { subject << issue }

            all   = subject.all
            first = all.first

            all.should == [issue]
            first.variations.size.should == 20
            first.variations.first.should == issue
        end
    end

    describe '#flatten' do
        it 'returns all issues as solo versions' do
            20.times { subject << issue }
            subject.flatten.size.should == 20
            subject.flatten.first.should == issue
            subject.flatten.map(&:solo?).uniq.should == [true]
        end
    end

    describe '#flatten' do
        it 'returns all issues as solo versions' do
            20.times { subject << issue }
            subject.flatten.size.should == 20
            subject.flatten.first.should == issue
            subject.flatten.map(&:solo?).uniq.should == [true]
        end
    end

    describe '#sort'do
        it 'returns a sorted array of Issues' do
            informational = issue.deep_clone
            informational.vector.action = 'http://test/1'
            informational.severity = Arachni::Issue::Severity::INFORMATIONAL
            subject << informational

            low = issue.deep_clone
            low.vector.action = 'http://test/2'
            low.severity = Arachni::Issue::Severity::LOW
            subject << low

            medium = issue.deep_clone
            medium.vector.action = 'http://test/3'
            medium.severity = Arachni::Issue::Severity::MEDIUM
            subject << medium

            high = issue.deep_clone
            high.vector.action = 'http://test/4'
            high.severity = Arachni::Issue::Severity::HIGH
            subject << high

            subject.sort.should == [high, medium, low, informational]
        end
    end

    describe '#each' do
        it 'passes each issue to the given block' do
            subject << issue
            issues = []
            subject.each { |i| issues << i }
            issues.should == [issue]
        end
    end

    describe '#include?' do
        context 'when it includes the given issue' do
            it 'returns true' do
                subject << issue
                subject.should include issue
            end
        end

        context 'when it does not includes the given issue' do
            it 'returns true' do
                subject << Factory[:active_issue]
                subject.should_not include issue
            end
        end
    end

    describe '#any?' do
        context 'when there are issues' do
            it 'returns true' do
                subject << issue
                subject.should be_any
            end
        end

        context 'when there are no issues' do
            it 'returns false' do
                subject.should_not be_any
            end
        end
    end

    describe '#empty?' do
        context 'when there are no issues' do
            it 'returns true' do
                subject.should be_empty
            end
        end

        context 'when there are issues' do
            it 'returns false' do
                subject << issue
                subject.should_not be_empty
            end
        end
    end

    describe '#size' do
        it 'returns the amount of issues' do
            subject << issue
            subject << Factory[:active_issue]
            subject.size.should == 2
        end
    end
end
