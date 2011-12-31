=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Reports

class HTML
module PluginFormatters

    #
    # HTML formatter for the results of the AutoLogin plugin
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class AutoLogin < Arachni::Plugin::Formatter

        def run
            return ERB.new( tpl ).result( binding )
        end

        def tpl
            %q{
                <% if @results[:cookies].is_a?( Hash )%>
                <h3>Cookies were set to:</h3>
                <ul>
                <% @results[:cookies].each_pair do |name, val|%>
                    <li><%=name%> = <%=val%></li>
                <%end%>
                <ul>
                <%end%>
            }

        end

    end

end
end

end
end
