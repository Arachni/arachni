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

opts = Arachni::Options.instance
require opts.dir['lib'] + 'parser/element/base'

module Arachni
class Parser
module Element

class Link < Base

    def initialize( url, raw = {} )
        super( url, raw )

        @action = @raw['href'] || @raw[:href] || @raw['action'] || @raw[:action] || url
        @method = 'get'

        @auditable = @raw['vars'] || @raw[:vars] || @raw['inputs'] || @raw[:inputs]
        @orig      = @auditable.deep_clone
        @orig.freeze
    end

    def http_request( opts )
        return @auditor.http.get( @action, opts )
    end

    def simple
        return { @action => @auditable }
    end

    def type
        Arachni::Module::Auditor::Element::LINK
    end

    def audit_id( injection_str = '', opts = {} )
        vars = auditable.keys.sort.to_s
        url = @action.gsub( /\?.*/, '' )

        str = ''
        str += !opts[:no_auditor] ? "#{@auditor.class.info[:name]}:" : ''

        str += "#{url}:" + "#{self.type}:#{vars}"
        str += "=#{injection_str.to_s}" if !opts[:no_injection_str]
        str += ":timeout=#{opts[:timeout]}" if !opts[:no_timeout]

        return str
    end


end

end
end
end
