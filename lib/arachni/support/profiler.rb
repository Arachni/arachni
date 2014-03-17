=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'ruby-mass'
require 'stackprof'
require 'sys/proctable'

module Arachni
module Support

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Profiler

    def trace_allocations
        require 'objspace'
        ObjectSpace.trace_object_allocations_start
    end

    def print_object_allocations( o )
        ap 'Object ID:   ' + o.object_id.to_s
        ap 'Source file: ' + ObjectSpace.allocation_sourcefile(o)
        ap 'Source line: ' + ObjectSpace.allocation_sourceline(o).to_s
        ap 'Generation:  ' + ObjectSpace.allocation_generation(o).to_s
        ap 'Class path:  ' + ObjectSpace.allocation_class_path(o).to_s
        ap 'Method:      ' + ObjectSpace.allocation_method_id(o).to_s
        ap 'Memsize:     ' + ObjectSpace.memsize_of(o).to_s
        #ap 'Reachable:   ' + ObjectSpace.reachable_objects_from(o).to_s  #=> [referenced, objects, ...]
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

    def print_object_space( options = {} )
        klass                = options[:class]
        namespaces           = options[:namespaces] || [Arachni]
        with_allocation_info = options[:with_allocation_info]
        with_references      = options[:with_references]
        with_dependencies    = options[:with_dependencies]
        max_entries          = options[:max_entries] || 50

        object_space    = Hash.new(0)
        @object_space ||= Hash.new(0)

        ObjectSpace.each_object do |o|
            next if o.class != klass || !object_within_namespace?( o, namespaces )

            print_object_allocations( o ) if with_allocation_info
            print_references( o )         if with_references
            print_dependencies( o )       if with_dependencies

            object_space[o.class] += 1
        end
        object_space = Hash[object_space.sort_by { |_, v| v }.reverse[0..max_entries]]

        with_deltas = object_space.dup
        with_deltas.each do |k, v|
            if v.is_a? Numeric
                with_deltas[k] = "#{v} (#{v - @object_space[k].to_i})"
            else
                with_deltas[k] = v
            end
        end

        ap with_deltas

        @object_space = object_space.dup
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
        namespaces.each do |namespace|
            return true if object.class.to_s.start_with?( namespace.to_s )
        end
        false
    end

end

end
end
