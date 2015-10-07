# encoding: utf-8
require 'spec_helper'

describe Arachni::Component::Utilities do

    before( :all ) do
        @utils = Arachni::Component::Utilities
    end

    describe '#read_file' do
        it 'reads a file from a directory with the same name as the caller and return an array of stripped lines' do
            filename = 'read_file.txt'
            filepath = File.expand_path( File.dirname( __FILE__ ) ) + '/utilities_spec/' + filename

            expect(@utils.read_file( filename ).join( "\n" )).to eq(IO.read( filepath ).strip)
        end

        context 'if a block is given' do
            it 'reads a file from a directory with the same name as the caller one stripped line at a time' do
                filename = 'read_file.txt'
                filepath = File.expand_path( File.dirname( __FILE__ ) ) + '/utilities_spec/' + filename

                lines = []
                @utils.read_file( filename ){ |line| lines << line }

                expect(lines.join( "\n" )).to eq(IO.read( filepath ).strip)
            end
        end
    end
end
