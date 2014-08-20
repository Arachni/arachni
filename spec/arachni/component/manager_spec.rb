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
            @components.lib.should == @lib
        end
    end

    describe '#namespace' do
        it 'returns the namespace under which all components are defined' do
            @components.namespace.should == @namespace
        end
    end

    describe '#available' do
        it 'returns all available components' do
            @components.available.sort.should == available
        end
    end

    describe '#load_all' do
        it 'loads all components' do
            @components.load_all
            @components.loaded.sort.should == @components.available.sort
        end
    end

    describe '#load' do
        context 'when passed a' do

            context String do
                it 'loads the component by name' do
                    @components.load( 'wait' )
                    @components.loaded.should == %w(wait)
                end
            end

            context Symbol do
                it 'loads the component by name' do
                    @components.load( :wait )
                    @components.loaded.should == %w(wait)
                end
            end

            context Array do
                it 'loads the components by name' do
                    @components.load( %w(bad distributable) )
                    @components.loaded.sort.should == %w(bad distributable).sort
                end
            end

            context 'vararg' do
                context String do
                    it 'loads components by name' do
                        @components.load( 'wait', 'bad' )
                        @components.loaded.sort.should == %w(bad wait).sort
                    end
                end

                context Symbol do
                    it 'loads components by name' do
                        @components.load :wait, :distributable
                        @components.loaded.sort.should == %w(wait distributable).sort
                    end
                end

                context Array do
                    it 'loads components by name' do
                        @components.load( :wait, %w(bad distributable) )
                        @components.loaded.sort.should == %w(bad distributable wait).sort
                    end
                end
            end

            context 'wildcard (*)' do
                context 'alone' do
                    it 'loads all components' do
                        @components.load( '*' )
                        @components.loaded.sort.should == @components.available.sort
                    end
                end

                context 'with a category name' do
                    it 'loads all of its components' do
                        @components.load( 'plugins/*' )
                        @components.loaded.sort.should == @components.available.sort
                    end
                end

            end

            context 'exclusion filter (-)' do
                context 'alone' do
                    it 'loads nothing' do
                        @components.load( '-' )
                        @components.loaded.sort.should be_empty
                    end
                end
                context 'with a name' do
                    it 'ignore that component' do
                        @components.load( %w(* -wait) )
                        loaded = @components.available
                        loaded.delete( 'wait' )
                        @components.loaded.sort.should == loaded.sort
                    end
                end
                context 'with a partial name and a wildcard' do
                    it 'ignore matching component names' do
                        @components.load( %w(* -wai* -dist*) )
                        loaded = @components.available
                        loaded.delete( 'wait' )
                        loaded.delete( 'distributable' )
                        @components.loaded.sort.should == loaded.sort
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
                    @components.empty?.should be_true
                    @components.load_by_tags( nil ).should == []
                end
            end

            context '[]' do
                it 'returns an empty array' do
                    @components.empty?.should be_true
                    @components.load_by_tags( [] ).should == []
                end
            end

            context String do
                it 'loads components whose tags include the given tag (as either a String or a Symbol)' do
                    @components.empty?.should be_true

                    @components.load_by_tags( 'wait_string' ).should == %w(wait)
                    @components.delete( 'wait' )
                    @components.empty?.should be_true

                    @components.load_by_tags( 'wait_sym' ).should == %w(wait)
                    @components.delete( 'wait' )
                    @components.empty?.should be_true

                    @components.load_by_tags( 'distributable_string' ).should == %w(distributable)
                    @components.delete( 'distributable' )
                    @components.empty?.should be_true

                    @components.load_by_tags( 'distributable_sym' ).should == %w(distributable)
                    @components.delete( 'distributable' )
                    @components.empty?.should be_true

                end
            end

            context Symbol do
                it 'loads components whose tags include the given tag (as either a String or a Symbol)' do
                    @components.empty?.should be_true

                    @components.load_by_tags( :wait_string ).should == %w(wait)
                    @components.delete( 'wait' )
                    @components.empty?.should be_true

                    @components.load_by_tags( :wait_sym ).should == %w(wait)
                    @components.delete( 'wait' )
                    @components.empty?.should be_true

                    @components.load_by_tags( :distributable_string ).should == %w(distributable)
                    @components.delete( 'distributable' )
                    @components.empty?.should be_true

                    @components.load_by_tags( :distributable_sym ).should == %w(distributable)
                    @components.delete( 'distributable' )
                    @components.empty?.should be_true
                end
            end

            context Array do
                it 'loads components which include any of the given tags (as either Strings or a Symbols)' do
                    @components.empty?.should be_true

                    expected = %w(wait distributable).sort
                    @components.load_by_tags( [ :wait_string, 'distributable_string' ] ).sort.should == expected
                    @components.clear
                    @components.empty?.should be_true

                    @components.load_by_tags( [ 'wait_string', :distributable_string ] ).sort.should == expected
                    @components.clear
                    @components.empty?.should be_true

                    @components.load_by_tags( [ 'wait_sym', :distributable_sym ] ).sort.should == expected
                    @components.clear
                    @components.empty?.should be_true
                end

            end
        end
    end

    describe '#parse' do
        context 'when passed a' do

            context String do
                it 'returns an array including the component\'s name' do
                    @components.parse( 'wait' ).should == %w(wait)
                end
            end

            context Symbol do
                it 'returns an array including the component\'s name' do
                    @components.parse( :wait ).should == %w(wait)
                end
            end

            context Array do
                it 'loads the component by name' do
                    @components.parse( %w(bad distributable) ).sort.should ==
                        %w(bad distributable).sort
                end
            end

            context 'wildcard (*)' do
                context 'alone' do
                    it 'returns all components' do
                        @components.parse( '*' ).sort.should == @components.available.sort
                    end
                end

                context 'with a category name' do
                    it 'returns all of its components' do
                        @components.parse( 'plugins/*' ).sort.should == @components.available.sort
                    end
                end

            end

            context 'exclusion filter (-)' do
                context 'alone' do
                    it 'returns nothing' do
                        @components.parse( '-' ).sort.should be_empty
                    end
                end
                context 'with a name' do
                    it 'ignores that component' do
                        @components.parse( %w(* -wait) )
                        loaded = @components.available
                        loaded.delete( 'wait' )
                        loaded.sort.should == loaded.sort
                    end
                end
                context 'with a partial name and a wildcard' do
                    it 'ignore matching component names' do
                        parsed = @components.parse( %w(* -wai* -dist*) )
                        loaded = @components.available
                        loaded.delete( 'wait' )
                        loaded.delete( 'distributable' )
                        parsed.sort.should == loaded.sort
                    end
                end
            end
        end
    end

    describe '#prepare_options' do
        it 'prepares options for passing to the component' do
            c = 'with_options'

            @components.load( c )
            @components.prepare_options( c, @components[c],
                { 'req_opt' => 'my value' }
            ).should == {
                req_opt:     'my value',
                default_opt: 'value'
            }

            opts = {
                'req_opt'     => 'req_opt value',
                'opt_opt'     => 'opt_opt value',
                'default_opt' => 'value2'
            }
            @components.prepare_options( c, @components[c], opts ).should == opts.symbolize_keys
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
            context String do
                it 'should load and return the component' do
                    @components.loaded.should be_empty
                    @components['wait'].name.should == 'Arachni::Plugins::Wait'
                    @components.loaded.should == %w(wait)
                end
            end
            context Symbol do
                it 'should load and return the component' do
                    @components.loaded.should be_empty
                    @components[:wait].name.should == 'Arachni::Plugins::Wait'
                    @components.loaded.should == %w(wait)
                end
            end
        end
    end

    describe '#include?' do
        context 'when passed a' do
            context String do
                context 'when the component has been loaded' do
                    it 'returns true' do
                        @components.loaded.should be_empty
                        @components['wait'].name.should == 'Arachni::Plugins::Wait'
                        @components.loaded.should == %w(wait)
                        @components.loaded?( 'wait' ).should be_true
                        @components.include?( 'wait' ).should be_true
                    end
                end
                context 'when the component has not been loaded' do
                    it 'returns false' do
                        @components.loaded.should be_empty
                        @components.loaded?( 'wait' ).should be_false
                        @components.include?( 'wait' ).should be_false
                    end
                end
            end
            context Symbol do
                context 'when the component has been loaded' do
                    it 'returns true' do
                        @components.loaded.should be_empty
                        @components[:wait].name.should == 'Arachni::Plugins::Wait'
                        @components.loaded.should == %w(wait)
                        @components.loaded?( :wait ).should be_true
                        @components.include?( :wait ).should be_true
                    end
                end
                context 'when the component has not been loaded' do
                    it 'returns false' do
                        @components.loaded.should be_empty
                        @components.loaded?( :wait ).should be_false
                        @components.include?( :wait ).should be_false
                    end
                end
            end
        end
    end

    describe '#delete' do
        it 'removes a component' do
            @components.loaded.should be_empty

            @components.load( 'wait' )
            klass = @components['wait']

            sym = klass.name.split( ':' ).last.to_sym
            @components.namespace.constants.include?( sym ).should be_true
            @components.loaded.should be_any

            @components.delete( 'wait' )
            @components.loaded.should be_empty

            sym = klass.name.split( ':' ).last.to_sym
            @components.namespace.constants.include?( sym ).should be_false
        end
        it 'unloads a component' do
            @components.loaded.should be_empty

            @components.load( 'wait' )
            klass = @components['wait']

            sym = klass.name.split( ':' ).last.to_sym
            @components.namespace.constants.include?( sym ).should be_true
            @components.loaded.should be_any

            @components.delete( 'wait' )
            @components.loaded.should be_empty

            sym = klass.name.split( ':' ).last.to_sym
            @components.namespace.constants.include?( sym ).should be_false
        end
    end

    describe '#loaded' do
        it 'returns all loaded components' do
            @components.load( '*' )
            @components.loaded.sort.should == available
        end
    end

    describe '#name_to_path' do
        it 'returns a component\'s path from its name' do
            path = @components.name_to_path( 'wait' )
            File.exists?( path ).should be_true
            File.basename( path ).should == 'wait.rb'
        end
    end

    describe '#path_to_name' do
        it 'returns a component\'s name from its path' do
            path = @components.name_to_path( 'wait' )
            @components.path_to_name( path ).should == 'wait'
        end
    end

    describe '#paths' do
        it 'returns all component paths' do
            paths = @components.paths
            paths.each { |p| File.exists?( p ).should be_true }
            paths.size.should == @components.available.size
        end
    end

    describe '#clear' do
        it 'unloads all components' do
            @components.loaded.should be_empty
            @components.load( '*' )
            @components.loaded.sort.should == @components.available.sort

            symbols = @components.values.map do |klass|
                sym = klass.name.split( ':' ).last.to_sym
                @components.namespace.constants.include?( sym ).should be_true
                sym
            end

            @components.clear
            symbols.each do |sym|
                @components.namespace.constants.include?( sym ).should be_false
            end
            @components.loaded.should be_empty
        end
    end
end
