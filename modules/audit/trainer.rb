=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules
module Audit

#
#
# Pokes and probes all inputs of a given page in order to uncover
# new input vectors.
#
# It also forces Arachni to train itself by analyzing the server responses.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
#
class Trainer < Arachni::Module::Base

    include Arachni::Module::Registrar

    def initialize( page )
        super( page )
    end
    
    def prepare( )
        
        # this will be the used as the injection string
        @str = '_arachni_trainer_' + Arachni::Module::Utilities.seed
        
        @opts = {
            #
            # tell the frameworm to learn from the
            # server responses that this module will cause.
            #
            :train  => true
        }
    end

    def run( )
      
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
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE,
                Vulnerability::Element::HEADER
            ],
            :author         => 'zapotek',
            :version        => '0.1',
            :references     => {
            },
            :targets        => { 'Generic' => 'all' },
        }
    end

end
end
end
end
