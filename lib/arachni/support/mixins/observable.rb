=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Support
module Mixins

# Provides a flexible way to make any object observable for multiple events.
#
# The observable classes use:
#
#    * `notify_<event>( *args )`
#
# to notify observers of events.
#
# The observers request notifications using:
#
#    * `observable.<event>( &block )`
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Observable
    include UI::Output
    include Utilities

    include MonitorMixin

    def self.included( base )
        base.extend ClassMethods
    end

    module ClassMethods
        def advertise( *ad_events )
            ad_events.each do |event|
                define_method event do |&block|
                    add_observer( event, &block )
                end

                define_method "notify_#{event}" do |*args|
                    notify_observers( event, *args )
                end

                private "notify_#{event}"
            end

            nil
        end
    end

    def initialize
        super

        @__observers = {}
    end

    private

    def observers
        @__observers
    end

    def add_observer( event, &block )
        fail ArgumentError, 'Missing block' if !block
        synchronize do
            observers_for( event ) << block
        end

        self
    end

    def notify_observers( event, *args )
        synchronize do
            observers_for( event ).each do |block|
                exception_jail( false ) { block.call( *args ) }
            end
        end

        nil
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
        synchronize do
            observers.clear
        end
    end

end

end
end
end
