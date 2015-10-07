require 'spec_helper'

describe Arachni::Framework::Parts::Plugin do
    include_examples 'framework'

    describe '#plugins' do
        it 'provides access to the plugin manager' do
            expect(subject.plugins.is_a?( Arachni::Plugin::Manager )).to be_truthy
            expect(subject.plugins.available.sort).to eq(
                %w(wait bad with_options distributable loop default suspendable).sort
            )
        end
    end

    describe '#list_plugins' do
        it 'returns info on all plugins' do
            expect(subject.list_plugins.size).to eq(subject.plugins.available.size)

            info   = subject.list_plugins.find { |p| p[:options].any? }
            plugin = subject.plugins[info[:shortname]]

            plugin.info.each do |k, v|
                if k == :author
                    expect(info[k]).to eq([v].flatten)
                    next
                end

                expect(info[k]).to eq(v)
            end

            expect(info[:shortname]).to eq(plugin.shortname)
        end

        context 'when a pattern is given' do
            it 'uses it to filter out plugins that do not match it' do
                subject.list_plugins( 'bad|foo' ).size == 2
                subject.list_plugins( 'boo' ).size == 0
            end
        end
    end

end
