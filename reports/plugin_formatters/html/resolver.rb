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
        # @author: Tasos "Zapotek" Laskos
        #                                      <tasos.laskos@gmail.com>
        #                                      <zapotek@segfault.gr>
        # @version: 0.1
        #
        class Resolver < Arachni::Plugin::Formatter

            def initialize( plugin_data )
                @results     = plugin_data[:results]
                @description = plugin_data[:description]
            end

            def run
                return ERB.new( tpl ).result( binding )
            end

            def tpl
                %q{
                    <h3>Results</h3>
                    <table>
                        <tr>
                            <th>
                                Hostname
                            </th>
                            <th>
                                IP Address
                            </th>
                        </tr>
                    <% @results.each do |hostname, ipaddress| %>
                        <tr>
                            <td>
                            <%= hostname %>
                            </td>
                            <td>
                            <%= ipaddress %>
                            </td>
                        </tr>
                    <%end%>
                    </table>
                }

            end

        end

    end
end

end
end
