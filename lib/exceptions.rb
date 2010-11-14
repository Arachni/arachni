=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

#
# Arachni::Exceptions module<br/>
# It holds the framework's exceptions.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
module Exceptions

    def initialize( msg )
        super( msg )
    end


    class NoAuditOpts < StandardError
        include Exceptions

    end

    class NoMods < StandardError
        include Exceptions

    end

    class ComponentNotFound < StandardError
        include Exceptions

    end

    class ModNotFound < StandardError
        include Exceptions

    end

    class DepModNotFound < StandardError
        include Exceptions

    end

    class ReportNotFound < StandardError
        include Exceptions

    end

    class NoURL < StandardError
        include Exceptions

    end

    class InvalidURL < StandardError
        include Exceptions

    end

    class NoCookieJar < StandardError
        include Exceptions

    end

end

end
