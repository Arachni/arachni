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
    # HTML formatter for the results of the HealthMap plugin
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class HealthMap < Arachni::Plugin::Formatter

        def run
            return ERB.new( tpl ).result( binding )
        end

        def tpl
            %q{
                <style type="text/css">
                    a.safe {
                        color: blue
                    }
                    a.unsafe {
                        color: red
                    }
                </style>

                <% @results[:map].each do |entry| %>
                    <% state = entry.keys[0]%>
                    <% url   = entry.values[0]%>

                    <a class="<%=state%>" href="<%=CGI.escapeHTML(url)%>"><%=CGI.escapeHTML(url)%></a> <br/>
                <%end%>

                <br/>

                <h3>Stats</h3>
                <strong>Total</strong>: <%=@results[:total]%> <br/>
                <strong>Safe</strong>: <%=@results[:safe]%> <br/>
                <strong>Unsafe</strong>: <%=@results[:unsafe]%> <br/>
                <strong>Issue percentage</strong>: <%=@results[:issue_percentage]%>%
            }
        end


    end

end
end

end
end
