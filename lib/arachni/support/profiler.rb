=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'objspace'
require 'sys/proctable'
require 'ruby-mass'
require 'stackprof'

module Arachni
module Support

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Profiler

    def self.write_samples_to_disk( file, options = {} )
        profiler = Support::Profiler.new
        # profiler.trace_allocations

        Thread.new do
            begin
                loop do
                    profiler.write_object_space( file, options )
                    sleep options[:interval] || 1
                end
            rescue => e
                ap e
                ap e.backtrace
            end
        end
    end

    def trace_allocations
        require 'objspace'
        ObjectSpace.trace_object_allocations_start
    end

    def print_object_allocations( o )
        ap 'Object ID:   ' + o.object_id.to_s
        ap 'Source file: ' + ObjectSpace.allocation_sourcefile(o)
        ap 'Source line: ' + ObjectSpace.allocation_sourceline(o).to_s
        # ap 'Generation:  ' + ObjectSpace.allocation_generation(o).to_s
        # ap 'Class path:  ' + ObjectSpace.allocation_class_path(o).to_s
        ap 'Method:      ' + ObjectSpace.allocation_method_id(o).to_s
        ap 'Memsize:     ' + ObjectSpace.memsize_of(o).to_s
        ap 'Reachable:   ' + ObjectSpace.reachable_objects_from(o).to_s  #=> [referenced, objects, ...]
        ap '-' * 200
    end

    def find_references( o )
        Mass.references( o )
    end

    def find_dependencies( _object_id, _mapped = {} )
        mapped = _mapped
        points_to_object = find_references( Mass[_object_id] )
        ids = points_to_object.keys.map { |x| /\#(\d*)/.match(x).captures.first.to_i }
        mapped[_object_id] = points_to_object#ids

        unmapped = ids - mapped.keys
        unmapped.each do |x|
            new_deps = find_dependencies( x, mapped )
            mapped.merge( new_deps )
        end
        mapped
    end

    def print_dependencies( o )
        ap 'Dependencies'
        ap find_dependencies( o.object_id )
    end

    def print_references( o )
        ap 'References'
        ap find_references( o )
    end

    def object_space( options = {} )
        klass       = options[:class]
        namespaces  = options[:namespaces] || [
            Arachni,
            Ethon,
            Typhoeus,
            Watir,
            Selenium,
            Addressable,
            Nokogiri,
            String,
            Hash,
            Array,
            Set,
            Thread
        ]

        max_entries = options[:max_entries] || 50

        object_space    = {}
        @object_space ||= {}

        ObjectSpace.each_object do |o|
            next if o.class != klass && !object_within_namespace?( o, namespaces )

            # if o.class == Page
            #     print_object_allocations( o )
            #
            #     # ap ObjectSpace.allocation_class_path( o ).to_s
            #     # ap "#{ObjectSpace.allocation_sourcefile( o )}:#{ObjectSpace.allocation_sourceline( o )}"
            #     # ap '-' * 120
            # end

            object_space[o.class] ||= {
                memsize: 0,
                count:   0
            }

            object_space[o.class][:memsize] += ObjectSpace.memsize_of(o)
            object_space[o.class][:count]   += 1
        end

        object_space = Hash[object_space.sort_by { |_, v| v[:count] }.reverse[0..max_entries]]

        with_deltas = {}
        object_space.each do |k, v|
            @object_space[k] ||= {
                memsize: 0,
                count:   0
            }

            if v[:count].is_a? Numeric
                with_deltas[k] = "#{v[:count]} (#{v[:count] - @object_space[k][:count]})"
                with_deltas[k] << " -- #{Utilities.bytes_to_megabytes v[:memsize]}"
                with_deltas[k] << " (#{Utilities.bytes_to_megabytes v[:memsize] - @object_space[k][:memsize]})"
            else
                with_deltas[k] = "#{v[:count]} -- #{Utilities.bytes_to_megabytes v[:memsize]}"
            end
        end

        @object_space = object_space.dup
        with_deltas

    rescue => e
        ap e
        ap e.backtrace
        {}
    end

    def write_object_space( file, options = {} )
        consumption = resource_consumption

        str = "RAM: #{consumption[:memory_usage].round(3)}MB"
        str << " (#{consumption[:memory_utilization]}%)"
        str << " - CPU: #{consumption[:cpu_utilization]}%\n\n"

        os      = object_space( options )
        maxsize = os.keys.map(&:to_s).map(&:size).sort.reverse.first

        os.each do |klass, info|
            offset = maxsize - klass.to_s.size
            str << "#{klass}: #{' ' * offset}#{info}\n"
        end

        IO.write( file, str )
    end

    def print_object_space( options = {} )
        ap object_space( options )
    end

    def count_objects( klass )
        ObjectSpace.each_object( klass ){}
    end

    def resource_consumption
        procinfo = ::Sys::ProcTable.ps( Process.pid )
        {
            cpu_utilization:    procinfo[:pctcpu],
            memory_utilization: procinfo[:pctmem],
            memory_usage:       rss_to_mb( procinfo[:rss] )
        }
    end

    def rss_to_mb( rss )
        rss * 4096.0 / 1024.0 / 1024.0
    end

    private

    def object_within_namespace?( object, namespaces )
        return true if namespaces.empty?

        namespaces.each do |namespace|
            return true if object.class.to_s.start_with?( namespace.to_s )
        end
        false
    end

end

end
end
