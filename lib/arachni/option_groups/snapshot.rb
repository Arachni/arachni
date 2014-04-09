=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni::OptionGroups

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Snapshot < Arachni::OptionGroup

    # @return    [String]
    #   Directory or file path where to store the scan snapshot.
    #
    # @see Framework#suspend
    attr_accessor :save_path

end
end

