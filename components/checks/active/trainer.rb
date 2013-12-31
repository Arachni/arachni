=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Pokes and probes all inputs of a given page in order to uncover new input vectors.
#
# It also forces Arachni to train itself by analyzing the server responses.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.2
class Arachni::Checks::Trainer < Arachni::Check::Base

    def run
        # The whole point of this check is to stir things up and find new
        # stuff, if our page limit has already been reached then we'll just be
        # wasting bandwidth.
        return if framework.page_limit_reached?

        audit( "_arachni_trainer_#{seed}", train: true, param_flip: true ){}
    end

    def self.info
        {
            name:        'Trainer',
            description: %q{Pokes and probes all inputs of a given page in order to uncover new input vectors.
                It also forces Arachni to train itself by analyzing the server responses.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            elements:    [ Element::Form, Element::Link, Element::Cookie, Element::Header ],
            version:     '0.1.2',
            targets:     %w(Generic)
        }
    end

end
