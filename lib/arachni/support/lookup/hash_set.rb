=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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
# Lightweight Set implementation.
#
# It uses the return value of the items' `#persistent_hash` instead of the
# items themselves.
#
# This leads to decreased memory consumption and faster comparisons during look-ups.
#
# @note If an `Integer` is passed as an argument it will be assumed that it is
#   already a hash and it will be stored as is.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class HashSet < Base

    def initialize
        @collection = Set.new
    end

end

end
end
