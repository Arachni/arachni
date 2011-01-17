=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

require Options.instance.dir['lib'] + 'module/manager'

module RPC
module XML
module Module

#
# We need to extend the original Manager and redeclare its inherited methods
# which are required over XMLRPC.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Manager < ::Arachni::Module::Manager

    # make these inherited methods visible again
    private :load, :available
    public :load, :available

    def initialize( opts )
        super( opts )
    end

end

end
end
end
end
