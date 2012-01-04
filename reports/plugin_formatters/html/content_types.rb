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
        # HTML formatter for the results of the ContentTypes plugin
        #
        # @author: Tasos "Zapotek" Laskos
        #                                      <tasos.laskos@gmail.com>
        #                                      <zapotek@segfault.gr>
        # @version: 0.1
        #
        class ContentTypes < Arachni::Plugin::Formatter

            def run
                return ERB.new( tpl ).result( binding )
            end

            def tpl
                %q{
                    <% @results.each_pair do |type, responses| %>
                        <ul>

                            <li>
                                <%=type%>
                                <ul>
                                    <% responses.each do |res| %>
                                    <li>
                                        URL: <a href="<%=CGI.escapeHTML(res[:url])%>"><%=CGI.escapeHTML(res[:url])%></a><br/>
                                        Method: <%=res[:method]%>

                                        <% if res[:params] && res[:method].downcase == 'post' %>
                                            <ul>
                                                <li>Parameters:</li>
                                                <%res[:params].each_pair do |name, val|%>
                                                <li>
                                                    <%=name%> = <%=val%>
                                                </li>
                                                <%end%>
                                            <ul>
                                        <%end%>
                                    </li>
                                    <%end%>
                                </ul>
                            </li>

                        </ul>

                    <%end%>
                }

            end

        end

    end
end

end
end
