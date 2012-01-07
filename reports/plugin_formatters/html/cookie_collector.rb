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
    # HTML formatter for the results of the CookieCollector plugin
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class CookieCollector < Arachni::Plugin::Formatter

        def run
            return ERB.new( tpl ).result( binding )
        end

        def tpl
            %q{
                <h3>Cookies</h3>
                <ul>
                <% @results.each do |entry| %>
                    <li>
                        On <%=entry[:time].to_s%> @ <a href="<%=CGI.escapeHTML(entry[:res]['effective_url'])%>"><%=CGI.escapeHTML(entry[:res]['effective_url'])%></a>
                        <br/>
                        Cookies were forced to:
                        <ul>
                            <% entry[:cookies].each_pair do |name, val| %>
                                <li><%=CGI.escapeHTML(name)%> = <%=CGI.escapeHTML(val)%></li>
                            <%end%>
                        </ul>
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
