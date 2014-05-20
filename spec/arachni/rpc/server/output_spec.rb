require 'spec_helper'

require Arachni::Options.instance.paths.lib + 'rpc/server/output'

class RPCOutput
    include Arachni::UI::Output
end

describe Arachni::UI::Output do
    before( :all ) do
        @opts = Arachni::Options.instance
        @out  = RPCOutput.new
        @out.mute
        @msg = 'This is a msg!'

        @logfile = @opts.paths.logs + 'output_spec.log'

        @e = Exception.new( 'Stuff' )
        @e.set_backtrace( [ 'backtrace line1', 'backtrace line2' ] )
    end

    after( :all ) { File.delete( @logfile ) }

    context 'when buffering the messages' do
        it 'does not hold more than 30 messages by default' do
            50.times { @out.print_error( @msg ) }
            @out.flush_buffer.size == 30
        end

        describe '#uncap_buffer' do
            it 'removes the buffer limits' do
                @out.uncap_buffer
                500.times { @out.print_error( @msg ) }
                @out.flush_buffer.size == 500
            end
        end

        describe '#set_buffer_cap' do
            it 'sets a buffer limit' do
                @out.set_buffer_cap( 50 )
                500.times { @out.print_error( @msg ) }
                @out.flush_buffer.size == 50
            end
        end

        describe '#print_error' do
            it 'logs an error' do
                @out.print_error( @msg )
                @out.flush_buffer.first.should == { error: @msg }
            end
        end

        describe '#print_error_backtrace' do
            it 'logs the backtrace from the provided exception' do
                @out.print_error_backtrace( @e )
                @out.flush_buffer.should == @e.backtrace.map { |l| { error: l } }
            end
        end

        describe '#print_bad' do
            it 'logs a bad msg' do
                @out.print_bad( @msg )
                @out.flush_buffer.first.should == { bad: @msg }
            end
        end

        context 'when only_positives is disabled' do

            describe '#only_positives?' do
                it 'returns true' do
                    @out.only_positives?.should be_false
                end
            end

            describe '#print_status' do
                it 'logs a status msg' do
                    @out.print_status( @msg )
                    @out.flush_buffer.first.should == { status: @msg }
                end
            end

            describe '#print_info' do
                it 'logs an informational msg' do
                    @out.print_info( @msg )
                    @out.flush_buffer.first.should == { info: @msg }
                end
            end

            describe '#print_line' do
                it 'logs a regular msg' do
                    @out.print_line( @msg )
                    @out.flush_buffer.first.should == { line: @msg }
                end
            end
        end

        context 'when only_positives is enabled' do
            before( :all ) { @out.only_positives }

            describe '#only_positives?' do
                it 'returns true' do
                    @out.only_positives?.should be_true
                end
            end

            describe '#print_status' do
                it 'logs a status msg' do
                    @out.print_status( @msg )
                    @out.flush_buffer.should be_empty
                end
            end

            describe '#print_info' do
                it 'logs an informational msg' do
                    @out.print_info( @msg )
                    @out.flush_buffer.should be_empty
                end
            end

            describe '#print_line' do
                it 'logs a regular msg' do
                    @out.print_line( @msg )
                    @out.flush_buffer.should be_empty
                end
            end
        end


        describe '#print_ok' do
            it 'logs an OK (successful) msg' do
                @out.print_ok( @msg )
                @out.flush_buffer.first.should == { ok: @msg }
            end
        end

        context 'with disabled verbosity' do
            describe '#verbose?' do
                it 'returns false' do
                    @out.verbose?.should be_false
                end
            end

            describe '#print_verbose' do
                it 'logs an OK (successful) msg' do
                    @out.print_verbose( @msg )
                    @out.flush_buffer.should be_empty
                end
            end
        end

        context 'with enabled verbosity' do
            before { @out.verbose }

            describe '#verbose?' do
                it 'returns true' do
                    @out.verbose?.should be_true
                end
            end

            describe '#print_verbose' do
                it 'logs a verbose msg' do
                    @out.print_verbose( @msg )
                    @out.flush_buffer.first.should == { verbose: @msg }
                end
            end
        end

        context 'when debugging is disabled' do

            describe '#debug?' do
                it 'returns false' do
                    @out.debug?.should be_false
                end
            end

            describe '#print_debug' do
                it 'does not log anything' do
                    @out.print_debug( @msg )
                    @out.flush_buffer.should be_empty
                end
            end

            describe '#print_debug_backtrace' do
                it 'does not log anything' do
                    @out.print_debug_backtrace( @e )
                    @out.flush_buffer.should be_empty
                end
            end
        end

        context 'when debugging is enabled' do
            before( :all ) { @out.debug }

            describe '#debug?' do
                it 'returns true' do
                    @out.debug?.should be_true
                end
            end

            describe '#print_debug' do
                it 'does not log anything' do
                    @out.print_debug( @msg )
                    @out.flush_buffer.should be_empty
                end
            end

            describe '#print_debug_backtrace' do
                it 'does not log anything' do
                    @out.print_debug_backtrace( @e )
                    @out.flush_buffer.should be_empty
                end
            end
        end
    end

    context 'when rerouting messages to a logfile' do
        before( :all ) do
            Arachni::UI::Output.reset_output_options
            @out.reroute_to_file( @logfile )
        end

        it 'sends output to the logfile' do
            @out.print_line( 'blah' )
            @out.flush_buffer.should be_empty
            IO.read( @logfile ).split( "\n" ).size == 1
        end
    end
end
