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

    context 'when rerouting messages to a logfile' do
        before( :all ) do
            Arachni::UI::Output.reset_output_options
            @out.reroute_to_file( @logfile )
        end

        it 'sends output to the logfile' do
            @out.print_line( 'blah' )
            expect(IO.read( @logfile ).split( "\n" ).size).to eq(1)
        end
    end
end
