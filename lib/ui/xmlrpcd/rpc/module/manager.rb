=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

require Options.instance.dir['lib'] + 'module/manager'

module UI
module RPCD
module Module
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Manager < ::Arachni::Module::Manager

    # make this inherited methods visible again
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
