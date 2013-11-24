=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

require Options.instance.dir['lib'] + 'module/utilities'

module Mixins

#
# Provides a flexible way to make any Class observable via callbacks/hooks
# using simple dynamic programming with the help of "method_missing()".
#
# The observable classes (those which include this module) use:
#
#    * call_<hookname>( *args )
#
# to call specific hooks.
#
# The observers set hooks using:
#
#    * observer_instance.add_<hookname>( &block )
#    * observer_instance.on_<hookname>( &block )
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Observable
    include Arachni::Utilities

    def clear_observers
        @__hooks.clear if @__hooks
    end

    def method_missing( sym, *args, &block )
        # grab the action (add/call) and the hook name
        action, hook = sym.to_s.split( '_', 2 )

        @__hooks       ||= {}
        @__hooks[hook] ||= []

        if action && hook
            case action
                when 'add', 'on'
                    add_block( hook, &block )
                    return

                 when 'call'
                    call_blocks( hook, args )
                    return
            end
        end

        fail NoMethodError.new( "Undefined method '#{sym.to_s}'.", sym, args )
    end

    private

    def add_block( hook, &block )
        @__hooks[hook] << block
    end

    def call_blocks( hook, *args )
        @__hooks[hook].each do |block|
            exception_jail {
                if args.first.size == 1
                    block.call( args.flatten[0] )
                else
                    block.call( *args )
                end
            }
        end
    end

end

end
end
