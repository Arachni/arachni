=begin
    Copyright 2010-2022 Ecsypno <http://www.ecsypno.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Rest
class Server

module InstanceHelpers

    @@instances = {}

    def instances
        @@instances
    end

    def scan_for( id )
        @@instances[id].service
    rescue => e
        instances.delete( id ).close
        session.delete id

        halt 500,
             json(
                 error:     "#{e.class}: #{e}",
                 backtrace: e.backtrace
             )
    end

    def exists?( id )
        instances.include? id
    end

    def kill_instance( id )
        Processes::Instances.kill( instances[id].url )
    end

end

end
end
end
