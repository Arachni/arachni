=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

require Options.dir['lib'] + 'module/manager'

module RPC
class Server
module Module

#
# We need to extend the original Manager and re-declare its inherited methods
# which are required over RPC.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Manager < ::Arachni::Module::Manager

    # make these inherited methods visible again
    private :load, :available, :loaded, :load_all
    public :load, :available, :loaded, :load_all

    def load( mods )
        @opts.mods = super( mods )
    end

end

end
end
end
end
