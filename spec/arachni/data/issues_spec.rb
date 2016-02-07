require 'spec_helper'

describe Arachni::Data::Issues do

    after(:each) do
        FileUtils.rm_rf @dump_directory if @dump_directory
    end

    subject { described_class.new }
    let(:issue) { Factory[:issue] }
    let(:active_issue){ Factory[:active_issue] }

    let(:issue_low_severity) do
        low = issue.deep_clone
        low.vector.action = 'http://test/2'
        low.severity = Arachni::Issue::Severity::LOW
        low
    end

    let(:issue_medium_severity) do
        medium = issue.deep_clone
        medium.vector.action = 'http://test/3'
        medium.severity = Arachni::Issue::Severity::MEDIUM
        medium
    end

    let(:issue_informational_severity) do
        informational = issue.deep_clone
        informational.vector.action = 'http://test/1'
        informational.severity = Arachni::Issue::Severity::INFORMATIONAL
        informational
    end

    let(:issue_high_severity) do
        high = issue.deep_clone
        high.vector.action = 'http://test/4'
        high.severity = Arachni::Issue::Severity::HIGH
        high
    end

    let(:unsorted_issues) do
        [issue_low_severity, issue_informational_severity, issue_high_severity,
        issue_medium_severity]
    end

    let(:sorted_issues) do
        [issue_high_severity, issue_medium_severity, issue_low_severity,
         issue_informational_severity]
    end

    let(:dump_directory) do
        @dump_directory = "#{Dir.tmpdir}/issues-#{Arachni::Utilities.generate_token}"
    end

    describe '#statistics' do
        let(:statistics) do
            unsorted_issues.each { |i| subject << i }
            subject.statistics
        end

        it 'includes the amount of total issues' do
            expect(statistics[:total]).to eq(subject.size)
        end

        it 'includes the amount of issues by severity' do
            expect(statistics[:by_severity]).to eq({
                low:           1,
                informational: 1,
                high:          1,
                medium:        1
            })
        end

        it 'includes the amount of issues by type' do
            expect(statistics[:by_type]).to eq({
                issue.name => 4
            })
        end

        it 'includes the amount of issues by check' do
            expect(statistics[:by_check]).to eq({
                issue.check[:shortname] => 4
            })
        end
    end

    describe '#<<' do
        it 'registers an array of issues' do
            subject << issue
            expect(subject.any?).to be_truthy
        end

        it 'does not register duplicate issues' do
            i = issue.deep_clone
            i.vector.affected_input_name = 'some input'
            20.times { subject << i }

            expect(subject.size).to eq(1)
        end
    end

    describe '#on_new' do
        it 'registers callbacks to be called on new issue' do
            callback_called = 0
            subject.on_new { callback_called += 1 }
            10.times { subject << active_issue }
            expect(callback_called).to eq(1)
        end
    end

    describe '#on_new_pre_deduplication' do
        it 'registers callbacks to be called on #<<' do
            callback_called = 0
            subject.on_new_pre_deduplication { callback_called += 1 }
            10.times { subject << issue }
            expect(callback_called).to eq(10)
        end
    end

    describe '#do_not_store' do
        it 'does not store results' do
            subject.do_not_store
            subject << issue
            expect(subject.empty?).to be_truthy
        end
    end

    describe '#all' do
        it 'returns all issues' do
            subject << issue
            expect(subject.all).to eq([issue])
        end
    end

    describe '#[]' do
        it 'provides access to issues by their #digest' do
            subject << issue
            expect(subject[issue.digest]).to eq(issue)
        end
    end

    describe '#sort'do
        it 'returns a sorted array of Issues' do
            unsorted_issues.each { |i| subject << i }
            expect(subject.sort).to eq(sorted_issues)
        end
    end

    describe '#each' do
        it 'passes each issue to the given block' do
            subject << issue
            issues = []
            subject.each { |i| issues << i }
            expect(issues).to eq([issue])
        end
    end

    describe '#map' do
        it 'passes each issue to the given block' do
            subject << issue
            expect(subject.map { |i| i.severity }).to eq([issue.severity])
        end
    end

    describe '#first' do
        it 'returns the first issue' do
            subject << issue_low_severity
            subject << issue_high_severity
            expect(subject.first).to eq(issue_low_severity)
        end
    end

    describe '#last' do
        it 'returns the last issue' do
            subject << issue_low_severity
            subject << issue_high_severity
            expect(subject.last).to eq(issue_high_severity)
        end
    end

    describe '#include?' do
        context 'when #do_not_store' do
            before(:each) { subject.do_not_store }

            context 'and it includes the given issue' do
                it 'returns true' do
                    subject << issue
                    expect(subject).to include issue
                end
            end
        end

        context 'when it includes the given issue' do
            it 'returns true' do
                subject << issue
                expect(subject).to include issue
            end
        end

        context 'when it does not includes the given issue' do
            it 'returns true' do
                subject << active_issue
                expect(subject.include?(issue)).to be_falsey
            end
        end
    end

    describe '#any?' do
        context 'when there are issues' do
            it 'returns true' do
                subject << issue
                expect(subject).to be_any
            end
        end

        context 'when there are no issues' do
            it 'returns false' do
                expect(subject).not_to be_any
            end
        end
    end

    describe '#empty?' do
        context 'when there are no issues' do
            it 'returns true' do
                expect(subject).to be_empty
            end
        end

        context 'when there are issues' do
            it 'returns false' do
                subject << issue
                expect(subject).not_to be_empty
            end
        end
    end

    describe '#size' do
        it 'returns the amount of issues' do
            subject << issue
            subject << active_issue
            expect(subject.size).to eq(2)
        end
    end

    describe '#dump' do
        it 'stores the issues to disk' do
            unsorted_issues.each { |i| subject << i }
            subject.dump( dump_directory )

            subject.each do |issue|
                issue_path = "#{dump_directory}/issue_#{issue.digest}"
                expect(File.exists?( issue_path )).to be_truthy

                loaded_issue = Marshal.load( IO.binread( issue_path ) )
                expect(issue).to eq(loaded_issue)
            end
        end

        it 'stores the #digests to disk' do
            unsorted_issues.each { |i| subject << i }
            subject.dump( dump_directory )

            expect(subject.digests).to eq(Marshal.load( IO.binread( "#{dump_directory}/digests" ) ))
        end
    end

    describe '.load' do
        it 'restores issues from disk' do
            unsorted_issues.each { |i| subject << i }
            subject.dump( dump_directory )

            expect(subject).to eq(described_class.load( dump_directory ))
        end

        it 'restores digests from disk' do
            unsorted_issues.each { |i| subject << i }
            subject.dump( dump_directory )

            expect(subject.digests).to eq(described_class.load( dump_directory ).digests)
        end
    end

    describe '#clear' do
        it 'clears the collection' do
            subject << issue
            subject.clear
            expect(subject).to be_empty
        end

        it 'clears #on_new callbacks' do
            callback_called = 0
            subject.on_new { callback_called += 1 }
            subject.clear

            10.times { subject << active_issue }
            expect(callback_called).to eq(0)
        end

        it 'clears #on_new_pre_deduplication callbacks' do
            callback_called = 0
            subject.on_new_pre_deduplication { callback_called += 1 }
            subject.clear

            10.times { subject << active_issue }
            expect(callback_called).to eq(0)
        end
    end
end
