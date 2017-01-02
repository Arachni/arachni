=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::HTML

#
# HTML formatter for the results of the HealthMap plugin
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
class PluginFormatters::HealthMap < Arachni::Plugin::Formatter
    include TemplateUtilities

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
            <style type="text/css">
                a.without_issues {
                    color: blue;
                }
                a.with_issues {
                    color: red;
                }
            </style>

            <div class="row">
                <div class="col-md-2">
                    <dl class="dl-horizontal">
                        <dt>
                            Total
                        </dt>
                        <dd>
                            <%= results['total'] %>
                        </dd>

                        <dt>
                            Without issues
                        </dt>
                        <dd>
                            <%= results['without_issues'] %>
                        </dd>

                        <dt>
                            With issues
                        </dt>
                        <dd>
                            <%= results['with_issues'] %>
                        </dd>

                        <dt>
                            Issue percentage
                        </dt>
                        <dd>
                            <%= results['issue_percentage'] %>
                        </dd>
                    </dl>
                </div>

                <div class="col-md-10">
                    <ul class="list-unstyled">
                    <% results['map'].sort_by { |entry| entry.keys.first }.each do |entry|
                            state, url = entry.to_a.first
                        %>

                        <li>
                            <a class="<%= state == 'with_issues' ? 'text-danger' : 'text-success' %>"
                                href="<%= escapeHTML url %>">
                                <%= escapeHTML url %>
                            </a>
                        </li>
                    <% end %>

                    </ul>
                </div>
            </div>
        HTML
    end

end
end
