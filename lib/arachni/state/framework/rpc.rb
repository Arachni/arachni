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

    # @return   [Support::Database::Queue]
    attr_reader :distributed_page_queue

    def initialize
        @distributed_pages      = Support::LookUp::HashSet.new( hasher: :persistent_hash )
        @distributed_elements   = Set.new
        @distributed_page_queue = Support::Database::Queue.new
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        page_queue_directory = "#{directory}/distributed_page_queue/"

        FileUtils.rm_rf( page_queue_directory )
        FileUtils.mkdir_p( page_queue_directory )

        distributed_page_queue.buffer.each do |page|
            File.open( "#{page_queue_directory}/#{page.persistent_hash}", 'w' ) do |f|
                f.write Marshal.dump( page )
            end
        end
        distributed_page_queue.disk.each do |filepath|
            FileUtils.cp filepath, "#{page_queue_directory}/"
        end

        %w(distributed_pages distributed_elements).each do |attribute|
            File.open( "#{directory}/#{attribute}", 'w' ) do |f|
                f.write Marshal.dump( send(attribute) )
            end
        end
    end

    def self.load( directory )
        rpc = new

        Dir["#{directory}/distributed_page_queue/*"].each do |page_file|
            rpc.distributed_page_queue.disk << page_file
        end

        rpc.distributed_elements.merge Marshal.load( IO.read( "#{directory}/distributed_elements" ) )
        rpc.distributed_pages.merge Marshal.load( IO.read( "#{directory}/distributed_pages" ) )

        rpc
    end

    def clear
        @distributed_pages.clear
        @distributed_elements.clear
        @distributed_page_queue.clear
    end

end

end
end
end

