=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::HTML

# HTML formatter for the results of the WAF Detector plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::WAFDetector < Arachni::Plugin::Formatter
    include TemplateUtilities

    def run
        ERB.new( tpl ).result( binding )
    end

    def tpl
        <<-HTML
            <h3>Result</h3>

            <p class="alert alert-<%= message_type %>">
                <b class="fa fa-<%= icon %>"></b>

                <strong><%= status %></strong>:
                <%= message %>
            </p>
        HTML
    end

    def status
        escapeHTML results['status'].capitalize
    end

    def message
        escapeHTML results['message'].capitalize.gsub( '_', ' ' )
    end

    def icon
        case results['status']
            when 'found'
                'check'

            when 'not_found'
                'times'

            when 'inconclusive'
                'question'
        end
    end

    def message_type
        case results['status']
            when 'found'
                'success'

            when 'not_found'
                'danger'

            when 'inconclusive'
                'warning'
        end
    end

end
end
