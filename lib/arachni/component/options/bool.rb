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

###
#
# Boolean option.
#
###
class Arachni::Component::Options::Bool < Arachni::Component::Options::Base
    TRUE_REGEX = /^(y|yes|t|1|true|on)$/i

    def type
        'bool'
    end

    def valid?( value )
        return false if empty_required_value?(value)

        if value && !value.to_s.empty? &&
            !value.to_s.match( /^(y|yes|n|no|t|f|0|1|true|false|on)$/i )
            return false
        end

        true
    end

    def normalize( value )
        if value.nil? || value.to_s.match( TRUE_REGEX ).nil?
            false
        else
            true
        end
    end

    def true?( value )
        normalize( value )
    end

    def false?( value )
        !true?( value )
    end
end
