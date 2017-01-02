=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

# The namespace under which all checks exist.
module Checks
end

module Check

# Manages and runs {Checks} against {Page}s.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Manager < Arachni::Component::Manager

    # Namespace under which all checks reside.
    NAMESPACE = ::Arachni::Checks

    # {Manager} error namespace.
    #
    # All {Manager} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Error

        # Raised when a loaded check targets invalid platforms.
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class InvalidPlatforms < Error
        end
    end

    # @param    [Arachni::Framework]  framework
    def initialize( framework )
        self.class.reset

        @framework = framework
        super( @framework.options.paths.checks, NAMESPACE )
    end

    # @param    [Arachni::Page]   page
    #   Page to audit.
    def run( page )
        schedule.each { |mod| exception_jail( false ){ run_one( mod, page ) } }
    end

    # @param    [Symbol, String]    name
    #   Name of the check to retrieve.
    #
    # @return   [Check::Base]
    #
    # @raise    [Error::InvalidPlatforms]
    #   On invalid check platforms.
    def []( name )
        check = super( name )

        if !Platform::Manager.valid?( check.platforms )
            unload name
            fail Error::InvalidPlatforms,
                 "Check #{name} contains invalid platforms: #{check.platforms.join(', ')}"
        end

        check
    end

    # @return   [Array]
    #   Checks in proper running order, taking account their declared
    #   {Check::Base.prefer preferences}.
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

    # @return   [Hash]
    #   Checks targeting specific platforms.
    def with_platforms
        select { |k, v| v.has_platforms? }
    end

    # @return   [Hash]
    #   Platform-agnostic checks.
    def without_platforms
        select { |k, v| !v.has_platforms? }
    end

    # Runs a single `check` against `page`.
    #
    # @param    [Check::Base]   check
    #   Check to run as a class.
    # @param    [Page]   page
    #   Page to audit.
    #
    # @return   [Bool]
    #   `true` if the check was ran (based on {Check::Auditor.check?}),
    #   `false` otherwise.
    def run_one( check, page )
        return false if !check.check?( page )

        check_new = check.new( page, @framework )
        check_new.prepare
        check_new.run
        check_new.clean_up

        true
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
