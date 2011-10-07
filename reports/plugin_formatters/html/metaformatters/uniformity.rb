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

class MetaModules
module MetaFormatters

    #
    # HTML formatter for the results of the Uniformity metamodule
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class Uniformity < Arachni::Plugin::Formatter

        def initialize( metadata )
            @results     = metadata[:results]
            @description = metadata[:description]
        end

        def run
            return ERB.new( tpl ).result( binding )
        end

        def tpl
            %q{
                    <h4>Uniformity (Lack of centralised sanitization)</h4>
                    <blockquote><pre><%=::Arachni::Reports::HTML.prep_description(@description)%></pre></blockquote>

                    <ul>
                    <%@results['uniformals'].each_pair do |id, uniformal| %>
                        <% issue = uniformal['issue'] %>
                        <li>
                            <%=issue['name']%> in <%=issue['elem']%> variable
                            '<%=issue['var']%>' using <%=issue['method']%> at the following pages:
                            <ul>

                            <%@results['pages'][id].each_with_index do |url, i|%>
                                <li>
                                    <a href="#issue_<%=uniformal['indices'][i]%>"><%=url%></a>
                                </li>
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
end
end
