=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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

class Array

    def chunk( pieces = 2 )
        return self if pieces <= 0

        len    = self.length;
        mid    = ( len / pieces )
        chunks = []
        start  = 0

        1.upto( pieces ) do |i|
            last = start + mid
            last = last - 1 unless len % pieces >= i
            chunks << self[ start..last ] || []
            start = last + 1
        end

        return chunks
    end

end
