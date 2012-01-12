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
module Modules

#
# Private IP address recon module.
#
# Scans every page for prvate IP addresses.
#
# @author   Tasos Laskos <tasos.laskos@gmail.com>
# @version   0.2
#
class PrivateIP < Arachni::Module::Base

    def run
        regexp = /(?<!\.)(?<!\d)(?:(?:10|127)\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)|192\.168|169\.254|172\.0?(?:1[6-9]|2[0-9]|3[01]))(?:\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){2}(?!\d)(?!\.)/
        match_and_log( regexp )
    end

    def self.info
        {
            :name           => 'Private IP address finder',
            :description    => %q{Scans pages for private IP addresses.},
            :author         => 'Tasos Laskos <tasos.laskos@gmail.com>',
            :version        => '0.2',
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Private IP address disclosure.},
                :description => %q{A private IP address is disclosured in the body of the HTML page},
                :cwe         => '200',
                :severity    => Issue::Severity::LOW,
                :cvssv2      => '0',
                :remedy_guidance    => %q{Remove private IP addresses from the body of the HTML pages.},
                :remedy_code => '',
            }
        }
    end

end
end
end
