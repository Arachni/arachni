=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::OptionGroups

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Snapshot < Arachni::OptionGroup

    # @return    [String]
    #   Directory or file path where to store the scan snapshot.
    #
    # @see Framework#suspend
    attr_accessor :save_path

    def initialize
        @save_path = Paths.config['framework']['snapshots']
    end

end
end

