require 'spec_helper'

describe Arachni::Component::Manager do
    before( :all ) do
        @opts = Arachni::Options.instance
        @lib = @opts.paths.plugins
        @namespace = Arachni::Plugins
        @components = Arachni::Component::Manager.new( @lib, @namespace )
    end
    let(:available) { %w(wait bad distributable loop default with_options suspendable).sort }
    after( :each ) { @components.clear }

    describe '#lib' do
        it 'returns the component library' do
            expect(@components.lib).to eq(@lib)
        end
    end

    describe '#namespace' do
        it 'returns the namespace under which all components are defined' do
            expect(@components.namespace).to eq(@namespace)
        end
    end

    describe '#available' do
        it 'returns all available components' do
            expect(@components.available.sort).to eq(available)
        end
    end

    describe '#load_all' do
        it 'loads all components' do
            @components.load_all
            expect(@components.loaded.sort).to eq(@components.available.sort)
        end
    end

    describe '#load' do
        context 'when passed a' do

            context 'String' do
                it 'loads the component by name' do
                    @components.load( 'wait' )
                    expect(@components.loaded).to eq(%w(wait))
                end
            end

            context 'Symbol' do
                it 'loads the component by name' do
                    @components.load( :wait )
                    expect(@components.loaded).to eq(%w(wait))
                end
            end

            context 'Array' do
                it 'loads the components by name' do
                    @components.load( %w(bad distributable) )
                    expect(@components.loaded.sort).to eq(%w(bad distributable).sort)
                end
            end

            context 'vararg' do
                context 'String' do
                    it 'loads components by name' do
                        @components.load( 'wait', 'bad' )
                        expect(@components.loaded.sort).to eq(%w(bad wait).sort)
                    end
                end

                context 'Symbol' do
                    it 'loads components by name' do
                        @components.load :wait, :distributable
                        expect(@components.loaded.sort).to eq(%w(wait distributable).sort)
                    end
                end

                context 'Array' do
                    it 'loads components by name' do
                        @components.load( :wait, %w(bad distributable) )
                        expect(@components.loaded.sort).to eq(%w(bad distributable wait).sort)
                    end
                end
            end

            context 'wildcard (*)' do
                context 'alone' do
                    it 'loads all components' do
                        @components.load( '*' )
                        expect(@components.loaded.sort).to eq(@components.available.sort)
                    end
                end

                context 'with a category name' do
                    it 'loads all of its components' do
                        @components.load( 'defaults/*' )
                        expect(@components.loaded.sort).to eq(%w(default))
                    end
                end

            end

            context 'exclusion filter (-)' do
                context 'alone' do
                    it 'loads nothing' do
                        @components.load( '-' )
                        expect(@components.loaded.sort).to be_empty
                    end
                end
                context 'with a name' do
                    it 'ignore that component' do
                        @components.load( %w(* -wait) )
                        loaded = @components.available
                        loaded.delete( 'wait' )
                        expect(@components.loaded.sort).to eq(loaded.sort)
                    end
                end
                context 'with a partial name and a wildcard' do
                    it 'ignore matching component names' do
                        @components.load( %w(* -wai* -dist*) )
                        loaded = @components.available
                        loaded.delete( 'wait' )
                        loaded.delete( 'distributable' )
                        expect(@components.loaded.sort).to eq(loaded.sort)
                    end
                end
            end
        end

        context 'when a component is not found' do
            it 'raises Arachni::Component::Error::NotFound' do
                trigger = proc { @components.load :houa }

                expect { trigger.call }.to raise_error Arachni::Error
                expect { trigger.call }.to raise_error Arachni::Component::Error
                expect { trigger.call }.to raise_error Arachni::Component::Error::NotFound
            end
        end
    end

    describe '#load_by_tags' do
        context 'when passed' do
            context 'nil' do
                it 'returns an empty array' do
                    expect(@components.empty?).to be_truthy
                    expect(@components.load_by_tags( nil )).to eq([])
                end
            end

            context '[]' do
                it 'returns an empty array' do
                    expect(@components.empty?).to be_truthy
                    expect(@components.load_by_tags( [] )).to eq([])
                end
            end

            context 'String' do
                it 'loads components whose tags include the given tag (as either a String or a Symbol)' do
                    expect(@components.empty?).to be_truthy

                    expect(@components.load_by_tags( 'wait_string' )).to eq(%w(wait))
                    @components.delete( 'wait' )
                    expect(@components.empty?).to be_truthy

                    expect(@components.load_by_tags( 'wait_sym' )).to eq(%w(wait))
                    @components.delete( 'wait' )
                    expect(@components.empty?).to be_truthy

                    expect(@components.load_by_tags( 'distributable_string' )).to eq(%w(distributable))
                    @components.delete( 'distributable' )
                    expect(@components.empty?).to be_truthy

                    expect(@components.load_by_tags( 'distributable_sym' )).to eq(%w(distributable))
                    @components.delete( 'distributable' )
                    expect(@components.empty?).to be_truthy

                end
            end

            context 'Symbol' do
                it 'loads components whose tags include the given tag (as either a String or a Symbol)' do
                    expect(@components.empty?).to be_truthy

                    expect(@components.load_by_tags( :wait_string )).to eq(%w(wait))
                    @components.delete( 'wait' )
                    expect(@components.empty?).to be_truthy

                    expect(@components.load_by_tags( :wait_sym )).to eq(%w(wait))
                    @components.delete( 'wait' )
                    expect(@components.empty?).to be_truthy

                    expect(@components.load_by_tags( :distributable_string )).to eq(%w(distributable))
                    @components.delete( 'distributable' )
                    expect(@components.empty?).to be_truthy

                    expect(@components.load_by_tags( :distributable_sym )).to eq(%w(distributable))
                    @components.delete( 'distributable' )
                    expect(@components.empty?).to be_truthy
                end
            end

            context 'Array' do
                it 'loads components which include any of the given tags (as either Strings or a Symbols)' do
                    expect(@components.empty?).to be_truthy

                    expected = %w(wait distributable).sort
                    expect(@components.load_by_tags( [ :wait_string, 'distributable_string' ] ).sort).to eq(expected)
                    @components.clear
                    expect(@components.empty?).to be_truthy

                    expect(@components.load_by_tags( [ 'wait_string', :distributable_string ] ).sort).to eq(expected)
                    @components.clear
                    expect(@components.empty?).to be_truthy

                    expect(@components.load_by_tags( [ 'wait_sym', :distributable_sym ] ).sort).to eq(expected)
                    @components.clear
                    expect(@components.empty?).to be_truthy
                end

            end
        end
    end

    describe '#parse' do
        context 'when passed a' do

            context 'String' do
                it 'returns an array including the component\'s name' do
                    expect(@components.parse( 'wait' )).to eq(%w(wait))
                end
            end

            context 'Symbol' do
                it 'returns an array including the component\'s name' do
                    expect(@components.parse( :wait )).to eq(%w(wait))
                end
            end

            context 'Array' do
                it 'loads the component by name' do
                    expect(@components.parse( %w(bad distributable) ).sort).to eq(
                        %w(bad distributable).sort
                    )
                end
            end

            context 'wildcard (*)' do
                context 'alone' do
                    it 'returns all components' do
                        expect(@components.parse( '*' ).sort).to eq(@components.available.sort)
                    end
                end

                context 'with a category name' do
                    it 'returns all of its components' do
                        expect(@components.parse( 'defaults/*' ).sort).to eq(%w(default))
                    end
                end
            end

            context 'exclusion filter (-)' do
                context 'alone' do
                    it 'returns nothing' do
                        expect(@components.parse( '-' ).sort).to be_empty
                    end
                end
                context 'with a name' do
                    it 'ignores that component' do
                        @components.parse( %w(* -wait) )
                        loaded = @components.available
                        loaded.delete( 'wait' )
                        expect(loaded.sort).to eq(loaded.sort)
                    end
                end
                context 'with a partial name and a wildcard' do
                    it 'ignore matching component names' do
                        parsed = @components.parse( %w(* -wai* -dist*) )
                        loaded = @components.available
                        loaded.delete( 'wait' )
                        loaded.delete( 'distributable' )
                        expect(parsed.sort).to eq(loaded.sort)
                    end
                end
            end
        end
    end

    describe '#prepare_options' do
        it 'prepares options for passing to the component' do
            c = 'with_options'

            @components.load( c )
            expect(@components.prepare_options( c, @components[c],
                { 'req_opt' => 'my value' }
            )).to eq({
                req_opt:     'my value',
                default_opt: 'value'
            })

            opts = {
                'req_opt'     => 'req_opt value',
                'opt_opt'     => 'opt_opt value',
                'default_opt' => 'value2'
            }
            expect(@components.prepare_options( c, @components[c], opts )).to eq(opts.my_symbolize_keys)
        end

        context 'with missing options' do
            it "raises #{Arachni::Component::Options::Error::Invalid}" do
                trigger = proc do
                    begin
                        c = 'with_options'
                        @components.load( c )
                        @components.prepare_options( c, @components[c], {} )
                    ensure
                        @components.clear
                    end
                end

                expect { trigger.call }.to raise_error Arachni::Component::Options::Error::Invalid
            end
        end

        context 'with invalid options' do
            it "raises #{Arachni::Component::Options::Error::Invalid}" do
                opts = {
                    'req_opt'     => 'req_opt value',
                    'opt_opt'     => 'opt_opt value',
                    'default_opt' => 'default_opt value'
                }

                trigger = proc do
                    begin
                        c = 'with_options'
                        @components.load( c )
                        @components.prepare_options( c, @components[c], opts )
                    ensure
                        @components.clear
                    end
                end

                expect { trigger.call }.to raise_error Arachni::Component::Options::Error::Invalid
            end
        end
    end

    describe '#[]' do
        context 'when passed a' do
            context 'String' do
                it 'should load and return the component' do
                    expect(@components.loaded).to be_empty
                    expect(@components['wait'].name).to eq('Arachni::Plugins::Wait')
                    expect(@components.loaded).to eq(%w(wait))
                end
            end
            context 'Symbol' do
                it 'should load and return the component' do
                    expect(@components.loaded).to be_empty
                    expect(@components[:wait].name).to eq('Arachni::Plugins::Wait')
                    expect(@components.loaded).to eq(%w(wait))
                end
            end
        end
    end

    describe '#include?' do
        context 'when passed a' do
            context 'String' do
                context 'when the component has been loaded' do
                    it 'returns true' do
                        expect(@components.loaded).to be_empty
                        expect(@components['wait'].name).to eq('Arachni::Plugins::Wait')
                        expect(@components.loaded).to eq(%w(wait))
                        expect(@components.loaded?( 'wait' )).to be_truthy
                        expect(@components.include?( 'wait' )).to be_truthy
                    end
                end
                context 'when the component has not been loaded' do
                    it 'returns false' do
                        expect(@components.loaded).to be_empty
                        expect(@components.loaded?( 'wait' )).to be_falsey
                        expect(@components.include?( 'wait' )).to be_falsey
                    end
                end
            end
            context 'Symbol' do
                context 'when the component has been loaded' do
                    it 'returns true' do
                        expect(@components.loaded).to be_empty
                        expect(@components[:wait].name).to eq('Arachni::Plugins::Wait')
                        expect(@components.loaded).to eq(%w(wait))
                        expect(@components.loaded?( :wait )).to be_truthy
                        expect(@components.include?( :wait )).to be_truthy
                    end
                end
                context 'when the component has not been loaded' do
                    it 'returns false' do
                        expect(@components.loaded).to be_empty
                        expect(@components.loaded?( :wait )).to be_falsey
                        expect(@components.include?( :wait )).to be_falsey
                    end
                end
            end
        end
    end

    describe '#delete' do
        it 'removes a component' do
            expect(@components.loaded).to be_empty

            @components.load( 'wait' )
            klass = @components['wait']

            sym = klass.name.split( ':' ).last.to_sym
            expect(@components.namespace.constants.include?( sym )).to be_truthy
            expect(@components.loaded).to be_any

            @components.delete( 'wait' )
            expect(@components.loaded).to be_empty

            sym = klass.name.split( ':' ).last.to_sym
            expect(@components.namespace.constants.include?( sym )).to be_falsey
        end
        it 'unloads a component' do
            expect(@components.loaded).to be_empty

            @components.load( 'wait' )
            klass = @components['wait']

            sym = klass.name.split( ':' ).last.to_sym
            expect(@components.namespace.constants.include?( sym )).to be_truthy
            expect(@components.loaded).to be_any

            @components.delete( 'wait' )
            expect(@components.loaded).to be_empty

            sym = klass.name.split( ':' ).last.to_sym
            expect(@components.namespace.constants.include?( sym )).to be_falsey
        end
    end

    describe '#loaded' do
        it 'returns all loaded components' do
            @components.load( '*' )
            expect(@components.loaded.sort).to eq(available)
        end
    end

    describe '#name_to_path' do
        it 'returns a component\'s path from its name' do
            path = @components.name_to_path( 'wait' )
            expect(File.exists?( path )).to be_truthy
            expect(File.basename( path )).to eq('wait.rb')
        end
    end

    describe '#path_to_name' do
        it 'returns a component\'s name from its path' do
            path = @components.name_to_path( 'wait' )
            expect(@components.path_to_name( path )).to eq('wait')
        end
    end

    describe '#paths' do
        it 'returns all component paths' do
            paths = @components.paths
            paths.each { |p| expect(File.exists?( p )).to be_truthy }
            expect(paths.size).to eq(@components.available.size)
        end
    end

    describe '#clear' do
        it 'unloads all components' do
            expect(@components.loaded).to be_empty
            @components.load( '*' )
            expect(@components.loaded.sort).to eq(@components.available.sort)

            symbols = @components.values.map do |klass|
                sym = klass.name.split( ':' ).last.to_sym
                expect(@components.namespace.constants.include?( sym )).to be_truthy
                sym
            end

            @components.clear
            symbols.each do |sym|
                expect(@components.namespace.constants.include?( sym )).to be_falsey
            end
            expect(@components.loaded).to be_empty
        end
    end
end
