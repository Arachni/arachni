=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'option_group'

# We need this to be available prior to loading the rest of the groups.
require_relative 'option_groups/paths'

Dir.glob( "#{File.dirname(__FILE__)}/option_groups/*.rb" ).each do |group|
    require group
end
