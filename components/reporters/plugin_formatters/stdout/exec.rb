=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

class Arachni::Reporters::Stdout

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class PluginFormatters::Exec < Arachni::Plugin::Formatter

    def run
        results.each do |stage, data|
            print_status "#{stage}: #{data['executable']}"
            print_info "Status:  #{data['status']}"
            print_info "PID:     #{data['pid']}"
            print_info "Runtime: #{data['runtime']}"
            print_info "STDOUT:  #{data['stdout']}"
            print_info "STDERR:  #{data['stderr']}"
        end
    end

end
end
