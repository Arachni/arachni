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
    # HTML formatter for the results of the TimeoutNotice metamodule
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class TimeoutNotice < Arachni::Plugin::Formatter

        def initialize( metadata )
            @results     = metadata[:results]
            @description = metadata[:description]
        end

        def run
            return ERB.new( tpl ).result( binding )
        end

        def tpl
            %q{
                    <h4>Timeout notice</h4>
                    <blockquote><pre><%=::Arachni::Reports::HTML.prep_description(@description)%></pre></blockquote>

                    <ul>
                    <%@results.each do |issue| %>
                        <li>
                            <a href="#issue_<%=issue['index']%>">
                                <%=issue['name']%> at <%=issue['url']%> in <%=issue['elem']%> variable '<%=issue['var']%>' using <%=issue['method']%>
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
end
end
