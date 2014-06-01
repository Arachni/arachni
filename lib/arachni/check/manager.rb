=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

#
# The namespace under which all checks exist.
#
module Checks
end

module Check

# Holds and manages the checks and their results.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Manager < Arachni::Component::Manager
    # Namespace under which all checks reside.
    NAMESPACE = ::Arachni::Checks

    # {Manager} error namespace.
    #
    # All {Manager} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Error

        # Raised when a loaded check targets invalid platforms.
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class InvalidPlatforms < Error
        end
    end

    # @param    [Arachni::Framework]  framework
    def initialize( framework )
        self.class.reset

        @framework = framework
        super( @framework.options.paths.checks, NAMESPACE )
    end

    # Runs all checks against 'page'.
    #
    # @param    [Arachni::Page]   page    Page to audit.
    def run( page )
        schedule.each { |mod| exception_jail( false ){ run_one( mod, page ) } }
    end

    def []( name )
        check = super( name )

        if !Platform::Manager.valid?( check.platforms )
            unload name
            fail Error::InvalidPlatforms,
                 "Check #{name} contains invalid platforms: #{check.platforms.join(', ')}"
        end

        check
    end

    # @return   [Array] Checks in proper running order.
    def schedule
        schedule       = Set.new
        preferred_over = Hash.new([])

        preferred = self.reject do |name, klass|
            preferred_over[name] = klass.preferred if klass.preferred.any?
        end

        return self.values if preferred_over.empty? || preferred.empty?

        preferred_over.size.times do
            update = {}
            preferred.each do |name, klass|
                schedule << klass
                preferred_over.select { |_, v| v.include?( name.to_sym ) }.each do |k, v|
                    schedule << (update[k] = self[k])
                end
            end

            preferred.merge!( update )
        end

        schedule |= preferred_over.keys.map { |n| self[n] }

        schedule.to_a
    end

    # @return   [Hash]  Checks which target specific platforms.
    def with_platforms
        select { |k, v| v.has_platforms? }
    end

    # @return   [Hash]  Checks which don't target specific platforms.
    def without_platforms
        select { |k, v| !v.has_platforms? }
    end

    # Runs a single check against 'page'.
    #
    # @param    [::Arachni::Check::Base]   check    Check to run as a class.
    # @param    [::Arachni::Page]   page    Page to audit.
    def run_one( check, page )
        return false if !check.check?( page )

        check_new = check.new( page, @framework )
        check_new.prepare
        check_new.run
        check_new.clean_up
    end

    def self.reset
        remove_constants( NAMESPACE )
    end
    def reset
        self.class.reset
    end

end
end
end
