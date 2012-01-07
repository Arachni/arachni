=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module UI
module Web
module Addons

#
#
# Sample add-on, see the code for examples.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
#
# @see http://www.sinatrarb.com/intro.html
#
# @version: 0.1
#
class Sample < Base

    #
    # This method gets fired when the plugin is loaded.
    #
    def run

        #
        # You can work with get/post/put/delete handlers just like
        # when using Sinatra.
        #
        get '/' do

            #
            # From inside the block you have access to regular Sinatra stuff
            # like sessions, helpers etc.
            #

            # session   => Direct access to the session, *be careful!*.
            # settings  => Direct access to the Sinatra methods, attributes, etc.

            # You can treat 'present' just like 'erb' with a default layout.
            present :index, :msg => 'world'
        end

    end

    #
    # This optional method allows you to specify the title which will be
    # used for the menu (in case you want it to be dynamic).
    #
    def title
        'Sample'
    end

    def self.info
        {
            :name           => 'Sample add-on',
            :description    => %q{This add-on serves as an example/tutorial.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1'
        }
    end


end

end
end
end
end
