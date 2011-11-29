=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

class Array

    def chunk( pieces = 2 )

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