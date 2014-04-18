=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

require Options.paths.lib + 'rpc/client/base'

module RPC
class Client

class Proxy < RemoteObjectMapper

    class <<self
        def translate( method_name, &translator )
            define_method method_name do |*args, &b|
                if b
                    return method_missing( method_name, *args ) do |data|
                        b.call *([data] + args)
                    end
                end

                translator.call *([method_missing( method_name, *args )] + args)
            end
        end
    end

end

end
end
end
