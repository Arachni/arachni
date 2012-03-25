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

module Arachni
module UI
module Web

#
# A simple logger using DataMapper
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.1.1
#
class Log

    class Entry
        include DataMapper::Resource

       def self.default_repository_name
         :log
       end

        property :id,           Serial
        property :action,       String
        property :object,       String
        property :client_addr,  String
        property :client_host,  String
        property :owner,        String
        property :datestamp,     DateTime
    end


    def initialize( opts, settings )

        @opts     = opts
        @settings = settings

        DataMapper::setup( :log, "sqlite3://#{@settings.db}/log.db" )
        DataMapper.repository( :log ) {
            DataMapper.finalize
            Entry.auto_upgrade!
        }
    end

    def entry
        DataMapper.repository( :log ) { Entry }
    end

    def method_missing( sym, *args, &block )

        owner, action = sym.to_s.split( '_', 2 )

        if args && args[1]
            object = args[1]
        end

        if env = args[0]
            addr = env['REMOTE_ADDR']
            host = env['REMOTE_HOST']
        end

        DataMapper.repository( :log ) {
            Entry.create(
                :action => action,
                :owner  => owner,
                :object => object,
                :client_addr => addr,
                :client_host => host,
                :datestamp   => Time.now.asctime
            )
        }
    end

end

end
end
end
