=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Pokes and probes all inputs of a given page in order to uncover new input vectors.
#
# It also forces Arachni to train itself by analyzing the server responses.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
class Arachni::Modules::Trainer < Arachni::Module::Base

    def run
        # The whole point of this module is to stir things up and find new
        # stuff, if our page limit has already been reached then we'll just be
        # wasting bandwidth.
        return if framework.link_count_limit_reached?

        audit( "_arachni_trainer_#{seed}", train: true, param_flip: true ){}
    end

    def self.info
        {
            name:        'Trainer',
            description: %q{Pokes and probes all inputs of a given page in order to uncover new input vectors.
                It also forces Arachni to train itself by analyzing the server responses.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            version:     '0.1.2',
            targets:     %w(Generic)
        }
    end

end
