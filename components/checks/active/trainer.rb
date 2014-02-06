=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Pokes and probes all inputs of a given page in order to uncover new input
# vectors and performs platforms fingerprinting of responses.
#
# It also forces Arachni to train itself by analyzing the server responses.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.3
class Arachni::Checks::Trainer < Arachni::Check::Base

    def run
        audit( "_arachni_trainer_#{seed}", train: true, param_flip: true ) do |response, _|
            # Forces the response to be fingerprinted as all pages automatically
            # get fingerprinted if that option has been enabled.
            response.to_page
        end
    end

    def self.info
        {
            name:        'Trainer',
            description: %q{Pokes and probes all inputs of a given page in order to uncover new input vectors.
                It also forces Arachni to train itself by analyzing the server responses.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            elements:    [ Element::Form, Element::Link, Element::Cookie, Element::Header ],
            version:     '0.1.3',
            targets:     %w(Generic)
        }
    end

end
