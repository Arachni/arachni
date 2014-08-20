=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
class State

# Stores and provides access to the state of all audit operations performed by:
#
#   * {Check::Auditor}
#       * {Check::Auditor.audited}
#       * {Check::Auditor#audited}
#       * {Check::Auditor#audited?}
#   * {Element::Capabilities::Auditable}
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Audit
    extend Forwardable

    def initialize
        @collection = Support::LookUp::HashSet.new( hasher: :persistent_hash )
    end

    def statistics
        {
            total: size
        }
    end

    [:<<, :merge, :include?, :clear, :empty?, :any?, :size, :hash, :==].each do |method|
        def_delegator :collection, method
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        IO.binwrite( "#{directory}/set", Marshal.dump( self ) )
    end

    def self.load( directory )
        Marshal.load( IO.binread( "#{directory}/set" ) )
    end

    private

    def collection
        @collection
    end

end

end
end
