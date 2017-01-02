=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class State
class Framework

# State information for {Arachni::RPC::Server::Framework}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class RPC

    # @return   [Support::LookUp::HashSet]
    attr_reader :distributed_pages

    # @return   [Set]
    attr_reader :distributed_elements

    def initialize
        @distributed_pages    = Support::LookUp::HashSet.new( hasher: :persistent_hash )
        @distributed_elements = Set.new
    end

    def statistics
        {
            distributed_pages:    @distributed_pages.size,
            distributed_elements: @distributed_elements.size
        }
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        %w(distributed_pages distributed_elements).each do |attribute|
            IO.binwrite( "#{directory}/#{attribute}", Marshal.dump( send(attribute) ) )
        end
    end

    def self.load( directory )
        rpc = new

        rpc.distributed_elements.merge Marshal.load( IO.binread( "#{directory}/distributed_elements" ) )
        rpc.distributed_pages.merge Marshal.load( IO.binread( "#{directory}/distributed_pages" ) )

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

