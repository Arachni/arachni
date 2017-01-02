=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::HTML

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::LoginScript < Arachni::Plugin::Formatter
    include TemplateUtilities

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
        <% if results['status'] == 'success' %>
                <p class="alert alert-success">
                    <%= results['message'] %>
                </p>

                <h3>Cookies set to:</h3>

                <dl class="dl-horizontal">
                    <% results['cookies'].each do |k, v| %>
                        <dt>
                            <code><%= escapeHTML( k ) %></code>
                        </dt>
                        <dd>
                            <code><%= escapeHTML( v ) %></code>
                        </dd>
                    <% end %>
                </dl>
        <% else %>
            <p class="alert alert-danger">
                <%= results['message'] %>
            </p>
        <% end %>
        HTML
    end

end

end
