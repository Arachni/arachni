=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

module RPC
class Client
class Instance

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Framework < Proxy

    def initialize( client )
        super client, 'framework'
    end

    translate :status do |status|
        status.to_sym if status
    end

    %w(list_reporters list_plugins).each do |m|
        translate m do |data|
            data.map do |c|
                c = c.my_symbolize_keys
                c[:options] = c[:options].map do |o|
                    o = o.my_symbolize_keys
                    o[:name] = o[:name].to_sym
                    o[:type] = o[:type].to_sym
                    o
                end
                c
            end
        end
    end

    translate :list_platforms do |platforms|
        platforms.inject({}) { |h, (k, v)| h[k] = v.my_symbolize_keys; h }
    end

    translate :statistics do |stats|
        stats.my_symbolize_keys
    end

    translate :progress do |data, options = {}|
        sitemap = data.delete('sitemap')
        issues  = data.delete('issues')

        data = data.my_symbolize_keys
        data[:status] = data[:status].to_sym

        if issues
            if options[:as_hash]
                data[:issues] = issues
            else
                data[:issues] = issues.map { |i| Arachni::Issue.from_rpc_data i }
            end
        end

        if data[:instances]
            data[:instances] = data[:instances].map(&:my_symbolize_keys)
        end

        if sitemap
            data[:sitemap] = sitemap
        end

        data
    end

    translate :issues do |issues|
        issues.map { |i| Arachni::Issue.from_rpc_data i }
    end

    translate :report do |data|
        Report.from_rpc_data data
    end

end

end
end
end
end
