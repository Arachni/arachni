=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

require_relative 'option_group'

Dir.glob( "#{File.dirname(__FILE__)}/option_groups/*.rb" ).each do |group|
    require group
end
