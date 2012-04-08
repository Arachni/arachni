require_relative '../../spec_helper'

describe Arachni::Module::KeyFiller do

    before( :all ) do
        @filler = Arachni::Module::KeyFiller
        @seeds = {}
        @filler.regexps.keys.each { |k| @seeds[k] = nil }
    end

    it 'should fill in all inputs with appropriate seed values' do
        @filler.fill( @seeds ).keys.compact.size == @seeds.size
    end

end
