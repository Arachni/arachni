=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

require 'set'

module Arachni
module Support::LookUp

#
# Lightweight look-up Set implementation.
#
# It uses stores hashes of items instead of the items themselves.
#
# This leads to decreased memory consumption and faster comparisons during look-ups.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class HashSet < Base

    # @param    (see Base#initialize)
    def initialize(*)
        super
        @collection = Set.new
    end

end

end
end
