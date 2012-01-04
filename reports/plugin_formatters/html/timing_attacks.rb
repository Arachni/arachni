=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Reports

class HTML
module PluginFormatters

    #
    # HTML formatter for the results of the TimingAttacks plugin.
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class TimingAttacks < Arachni::Plugin::Formatter

        def run
            return ERB.new( tpl ).result( binding )
        end

        def tpl
            %q{
                    <ul>
                    <%@results.each do |issue| %>
                        <li>
                            <a href="#issue_<%=issue['index']%>">
                                [#<%=issue['index']%>]
                                <%=issue['name']%> at <%=issue['url']%> in
                                <%=issue['elem']%> variable '<%=issue['var']%>'
                                using <%=issue['method']%>
                            </a>
                        </li>
                    <%end%>
                    </ul>
            }
        end
    end

end
end
end
end
