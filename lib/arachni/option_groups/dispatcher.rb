=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::OptionGroups

# Holds options for {RPC::Server::Dispatcher} servers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Dispatcher < Arachni::OptionGroup

    # @return   [Array<Symbol>] Supported {#grid_mode grid modes}.
    GRID_MODES = [:balance, :aggregate]

    # @return   [String]
    #   URL of a {RPC::Server::Dispatcher} (used by the {UI::CLI::RPC} client
    #   interface).
    attr_accessor :url

    # @return   [String]
    #   External (hostname or IP) address for the {RPC::Server::Dispatcher}
    #   to advertise.
    attr_accessor :external_address

    # @return   [Integer]
    #   Amount of {RPC::Server::Instance}s to keep in the
    #   {RPC::Server::Dispatcher} pool.
    attr_accessor :pool_size

    # @return   [Array<Integer>]
    #   Range of ports to use when spawning instances, first entry should be
    #   the lowest port number, last the max port number.
    attr_accessor :instance_port_range

    # @return   [nil, Symbol]
    #   Grid mode to use for multi-{RPC::Server::Instance} scans with
    #   interconnected {RPC::Server::Dispatcher}s, available modes are:
    #
    #   * `nil` -- No grid.
    #   * `:balance` -- Default load balancing across available Dispatchers.
    #   * `:aggregate` -- Default load balancing **with** line aggregation.
    #       Will only request Instances from Grid members with different
    #       {OptionGroups::Dispatcher#node_pipe_id Pipe-IDs}.
    attr_accessor :grid_mode

    # @return   [String]
    #   The URL of a neighbouring {RPC::Server::Dispatcher}, applicable when
    #   {RPC::Server::Dispatcher} are connected to each other to form a Grid.
    #
    # @see RPC::Server::Dispatcher::Node
    attr_accessor :neighbour

    # @return   [Float]
    #   How soon to check for {OptionGroups::Dispatcher#neighbour} node status.
    attr_accessor :node_ping_interval

    # @return   [Float]
    #   Cost of using this Dispatcher node.
    attr_accessor :node_cost

    # @return   [String]
    #   A string identifying the bandwidth pipe used by this Dispatcher node.
    attr_accessor :node_pipe_id

    # @return   [Float]
    #   Weight used to calculate the score of this Dispatcher node.
    attr_accessor :node_weight

    # @return   [String]
    #   Dispatcher node nickname.
    attr_accessor :node_nickname

    set_defaults(
        node_ping_interval:  60.0,
        instance_port_range: [1025, 65535],
        pool_size:           5
    )

    # @return   [Bool]
    #   `true` if the Grid should be used, `false` otherwise.
    def grid?
        !!@grid_mode
    end

    # @param    [Bool]  bool
    #   `true` to use the Grid, `false` otherwise. Serves as a shorthand to
    #   setting {OptionGroups::Dispatcher#grid_mode} to `:balance`.
    def grid=( bool )
        @grid_mode = bool ? :balance : nil
    end

    # @param    [String, Symbol]    mode
    #   Grid mode to use for multi-{RPC::Server::Instance} scans with
    #   interconnected {RPC::Server::Dispatcher}s, available modes are:
    #
    #   * `nil` -- No grid.
    #   * `:balance` -- Default load balancing across available Dispatchers.
    #   * `:aggregate` -- Default load balancing **with** line aggregation.
    #       Will only request Instances from Grid members with different
    #       {OptionGroups::Dispatcher#node_pipe_id Pipe-IDs}.
    #
    # @raise    [ArgumentError]
    #   On invalid mode.
    def grid_mode=( mode )
        return @grid_mode = nil if !mode

        mode = mode.to_sym
        if !GRID_MODES.include?( mode )
            fail ArgumentError, "Unknown grid mode: #{mode}"
        end

        @grid_mode = mode
    end

    # @return   [Bool]
    #   `true` if the grid mode is in line-aggregation mode, `false` otherwise.
    def grid_aggregate?
        @grid_mode == :aggregate
    end

    # @return   [Bool]
    #   `true` if the grid mode is in load-balancing mode, `false` otherwise.
    def grid_balance?
        @grid_mode == :balance
    end

end
end
