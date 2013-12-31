=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'option_group'

Dir.glob( "#{File.dirname(__FILE__)}/option_groups/*.rb" ).each do |group|
    require group
end
