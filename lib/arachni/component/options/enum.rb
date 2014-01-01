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
# Enum option.
#
###
class Arachni::Component::Options::Enum < Arachni::Component::Options::Base
    def type
        'enum'
    end

    def valid?( value = self.value )
        return false if empty_required_value?( value )
        value && self.enums.include?( value.to_s )
    end

    def normalize( value = self.value )
        return nil if !self.valid?( value )
        value.to_s
    end

    def desc=( value )
        self.desc_string = value
        self.desc
    end

    def desc
        if self.enums
            str = self.enums.join( ', ' )
        end
        "#{self.desc_string || @desc || ''} (accepted: #{str})"
    end

    protected
    attr_accessor :desc_string # :nodoc:
end
