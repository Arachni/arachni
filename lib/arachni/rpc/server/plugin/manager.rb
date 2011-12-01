=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

require Options.instance.dir['lib'] + 'plugin/manager'

module RPC
class Server
module Plugin

#
# We need to extend the original Manager and redeclare its inherited methods
# which are required over RPC.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class Manager < ::Arachni::Plugin::Manager

    # make these inherited methods visible again
    private :available
    public  :available

    def initialize( framework )
        super( framework )

        @plugin_opts = {}
    end

    def load( plugins )
        @plugin_opts.merge!( plugins )
        super( plugins.keys )

        @framework.opts.plugins = plugins
    end

    def create( name )
        self[name].new( @framework, prep_opts( name, self[name], @plugin_opts[name] ) )
    end


end

end
end
end
end
