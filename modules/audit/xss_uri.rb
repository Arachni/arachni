=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Modules

#
# Left here for compatibility reasons, has been obsoleted by the xss_path module.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
#
class XSSURI < Arachni::Module::Base

    def prepare
        if @framework && !@framework.modules.keys.include?( 'xss_path' )
            @mod = @framework.modules['xss_path'].new( @page )
            @mod.set_framework( @framework )
            @mod.prepare
        end
    end

    def run
        print_bad( 'Module has been obsoleted and will eventually be removed.' )
        print_bad( 'Please remove it from any profiles or scripts you may have created.' )
        print_bad( '-- Running \'xss_path\' instead.' )
        @mod.run if @mod
    end

    def clean_up
        @mod.clean_up if @mod
    end

    def self.info
        {
            :name           => 'XSSURI',
            :description    => %q{Compatibility module, will load and run xss_path instead.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0'
        }
    end

end
end
end
