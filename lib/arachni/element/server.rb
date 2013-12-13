=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require Arachni::Options.dir['lib'] + 'element/base'

module Arachni::Element
class Server < Base

    attr_accessor :auditor

    def initialize( response )
        @response = response
        super url: response.url
    end

    def action
        url
    end

    def remove_auditor
        @auditor = nil
    end

    def dup
        self.class.new( @response ).tap { |s| s.auditor = @auditor }
    end

    def hash
        to_h.hash
    end

    def ==( other )
        hash == other.hash
    end

    # @note Ignores custom 404 responses.
    #
    # Logs a remote file or directory if it exists.
    #
    # @param    [String]    url Resource to check.
    # @param    [Bool]      silent
    #   If `false`, a message will be printed to stdout containing the status of
    #   the operation.
    # @param    [Proc]      block
    #   Called if the file exists, just before logging the issue, and is passed
    #   the HTTP response.
    #
    # @return   [Object]
    #   * `nil` if no URL was provided.
    #   * `false` if the request couldn't be fired.
    #   * `true` if everything went fine.
    #
    # @see #remote_file_exist?
    def log_remote_file_if_exists( url, silent = false, &block )
        return nil if !url

        auditor.print_status( "Checking for #{url}" ) if !silent
        remote_file_exist?( url ) do |bool, res|
            auditor.print_status( 'Analyzing response for: ' + url ) if !silent
            next if !bool

            block.call( res ) if block_given?
            auditor.log_remote_file( res )

            # If the file exists let the trainer parse it since it may contain
            # brand new data to audit.
            auditor.framework.trainer.push( res )
        end
        true
    end
    alias :log_remote_directory_if_exists :log_remote_file_if_exists

    # @note Ignores custom 404 responses.
    #
    # Checks whether or not a remote resource exists.
    #
    # @param    [String]    url Resource to check.
    # @param    [Block] block
    #   Block to be passed  `true` if the resource exists, `false` otherwise.
    #
    # @return   [Object]
    #   * `nil` if no URL was provided.
    #   * `false` if the request couldn't be fired.
    #   * `true` if everything went fine.
    def remote_file_exist?( url, &block )
        request = auditor.http.get( url, performer: self )
        return false if !request

        request.on_complete do |response|
            if response.code != 200
                block.call( false, response )
            else
                auditor.http.custom_404?( response ) { |bool| block.call( !bool, response ) }
            end
        end

        true
    end
    alias :remote_file_exists? :remote_file_exist?

end
end
