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

class Arachni::Modules::Test3 < Arachni::Module::Base

    prefer :test2

    def self.info
        {
            :name           => 'Test3 module',
            :description    => %q{Test description},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1',
            :references     => {
                'Wikipedia'  => 'http://en.wikipedia.org/'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Test issue},
                :description => %q{Test description},
                :tags        => [ 'some', 'tag' ],
                :cwe         => '0',
                :severity    => Issue::Severity::HIGH,
                :cvssv2      => '0',
                :remedy_guidance    => %q{Watch out!.},
                :remedy_code => '',
                :metasploitable => 'unix/webapp/blah'
            }

        }
    end

end
