=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class State
class Framework

# State information for {Arachni::RPC::Server::Framework}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class RPC

    # @return   [Support::LookUp::HashSet]
    attr_reader :distributed_pages

    # @return   [Set]
    attr_reader :distributed_elements

    def initialize
        @distributed_pages      = Support::LookUp::HashSet.new( hasher: :persistent_hash )
        @distributed_elements   = Set.new
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        %w(distributed_pages distributed_elements).each do |attribute|
            File.open( "#{directory}/#{attribute}", 'w' ) do |f|
                f.write Marshal.dump( send(attribute) )
            end
        end
    end

    def self.load( directory )
        rpc = new

        rpc.distributed_elements.merge Marshal.load( IO.read( "#{directory}/distributed_elements" ) )
        rpc.distributed_pages.merge Marshal.load( IO.read( "#{directory}/distributed_pages" ) )

        rpc
    end

    def clear
        @distributed_pages.clear
        @distributed_elements.clear
    end

end

end
end
end

