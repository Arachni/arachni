=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni

require Options.paths.lib + 'check/manager'

module RPC
class Server

# @private
module Check

# We need to extend the original Manager and re-declare its inherited methods
# which are required over RPC.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Manager < ::Arachni::Check::Manager

    # make these inherited methods visible again
    private :load, :available, :loaded, :load_all
    public :load, :available, :loaded, :load_all

    def load( checks )
        @framework.options.checks = super( checks )
    end

end

end
end
end
end
