require 'spec_helper'

describe Arachni::Report::Manager do
    before( :all ) do
        opts = Arachni::Options.instance
        opts.paths.reports = fixtures_path + 'reports/manager_spec/'

        @framework = Arachni::Framework.new( Arachni::Options.instance )
        @reports   = @framework.reports
        @reports.load( '*' )
    end

    after( :all ){ @reports.clear }

    describe '#run' do
        context 'without the run_afr opt' do
            it 'runs loaded reports including the AFR one' do
                @reports.run( @framework.auditstore )

                File.exist?( 'afr' ).should be_true
                File.delete( 'afr' )

                @reports.keys.each do |name|
                    File.exist?( name ).should be_true
                    File.delete( name )
                end
            end
        end
        context 'with the run_afr opt set to true' do
            it 'runs loaded reports including the AFR one' do
                @reports.run( @framework.auditstore, true )
                File.exist?( 'afr' ).should be_true
                File.delete( 'afr' )

                @reports.keys.each do |name|
                    File.exist?( name ).should be_true
                    File.delete( name )
                end
            end
        end
        context 'with run_afr opt set to false' do
            it 'runs loaded reports without the AFR one' do
                @reports.run( @framework.auditstore, false )
                File.exist?( 'afr' ).should be_false

                @reports.keys.each do |name|
                    File.exist?( name ).should be_true
                    File.delete( name )
                end
            end
        end
    end

    describe '#run_one' do
        it 'runs a report by name' do
            @reports.run_one( 'foo', @framework.auditstore )

            File.exist?( 'foo' ).should be_true
            File.delete( 'foo' )
        end

        context 'when passed options' do
            it 'overrides Options.reports' do
                Arachni::Options.reports[:foo] = { 'outfile' => 'stuff1' }
                opts = { 'outfile' => 'stuff' }
                report = @reports.run_one :foo, @framework.auditstore, opts
                report.options.should eq opts
                File.delete( 'foo' )
            end
        end

        context 'when not passed options' do
            it 'falls back to Options.reports' do
                opts = Arachni::Options.reports[:foo] = { 'outfile' => 'stuff2' }
                report = @reports.run_one :foo, @framework.auditstore
                report.options.should eq opts
                File.delete( 'foo' )
            end
        end
    end

end
