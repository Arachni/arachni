=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

module RPC
class Client
class Instance

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Framework < Proxy

    def initialize( client )
        super client, 'framework'
    end

    translate :status do |status|
        status.to_sym if status
    end

    %w(list_reports list_plugins).each do |m|
        translate m do |data|
            data.map do |c|
                c = c.symbolize_keys
                c[:options] = c[:options].map do |o|
                    o = o.symbolize_keys
                    o[:name] = o[:name].to_sym
                    o[:type] = o[:type].to_sym
                    o
                end
                c
            end
        end
    end

    translate :list_platforms do |platforms|
        platforms.inject({}) { |h, (k, v)| h[k] = v.symbolize_keys; h }
    end

    translate :statistics do |stats|
        stats.symbolize_keys
    end

    translate :progress do |data, options = {}|
        data = data.symbolize_keys
        data[:status] = data[:status].to_sym

        if data[:issues] && !options[:as_hash]
            data[:issues] = data[:issues].map { |i| Arachni::Issue.from_rpc_data i }
        end

        if data[:instances]
            data[:instances] = data[:instances].map(&:symbolize_keys)
        end

        data
    end

    translate :issues do |issues|
        issues.map { |i| Arachni::Issue.from_rpc_data i }
    end

    [:auditstore, :audit_store].each do |m|
        translate m do |data|
            AuditStore.from_rpc_data data
        end
    end

end

end
end
end
end
