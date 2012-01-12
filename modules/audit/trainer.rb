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
#
# Pokes and probes all inputs of a given page in order to uncover
# new input vectors.
#
# It also forces Arachni to train itself by analyzing the server responses.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
#
class Trainer < Arachni::Module::Base

    include Arachni::Module::Utilities

    def prepare

        # this will be the used as the injection string
        @str = '_arachni_trainer_' + seed

        @opts = {
            #
            # tell the framework to learn from the
            # server responses that this module will cause.
            #
            :train  => true,
            :param_flip => true
        }
    end

    def run
        #
        # this will inject the string in @str into all available inputs
        #
        audit( @str, @opts ) {
            #
            # empty block, we don't need to check for anything
            #
            # however since we haven't passed at least a regexp to audit()
            # we need to provide a block otherwise the Auditor will complain...
            #
            # that bastard!
            #
        }
    end

    def self.info
        {
            :name           => 'Trainer',
            :description    => %q{Pokes and probes all inputs of a given page in order to uncover new input vectors.
                It also forces Arachni to train itself by analyzing the server responses.},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE,
                Issue::Element::HEADER
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1.1',
            :references     => {
            },
            :targets        => { 'Generic' => 'all' },
        }
    end

end
end
end
