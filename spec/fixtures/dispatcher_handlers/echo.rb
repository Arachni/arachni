class Arachni::RPC::Server::Dispatcher
class Handler::Echo < Handler

    def echo( *args )
        args
    end

    def jobs
        dispatcher.jobs
    end

    def hash_opts
        opts.to_hash
    end

    def async( &block )
        ::EM.defer{ block.call true }
        false
    end

end
end
