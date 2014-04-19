=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Class
    def to_msgpack( *args )
        to_s.to_msgpack(*args)
    end
end
