=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Mixins

# Provides a flexible way to make any `Class` observable for multiple events.
#
# The observable classes use:
#
#    * `call_<event>( *args )`
#
# to call specific hooks.
#
# The observers set hooks using:
#
#    * `observable.on_<event>( &block )`
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Observable
    include Utilities

    def self.included( base )
        base.extend ClassMethods
    end

    module ClassMethods
        def advertise( *ad_events )
            ad_events.each do |event|
                define_method event do |&block|
                    fail ArgumentError, 'Missing block' if !block
                    observers_for( event ) << block
                    self
                end

                define_method "call_#{event}" do |*args|
                    observers_for( event ).each do |block|
                        exception_jail { block.call( *args ) }
                    end

                    nil
                end

                private "call_#{event}"
            end

            nil
        end
    end

    private

    def observers
        @__observers ||= {}
    end

    def dup_observers
        observers.inject({}) { |h, (k, v)| h[k] = v.dup; h }
    end

    def set_observers( obs )
        @__observers = obs
    end

    def observers_for( event )
        observers[event.to_sym] ||= []
    end

    def clear_observers
        observers.clear
    end

end

end
end
