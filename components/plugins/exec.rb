=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'open3'

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class Arachni::Plugins::Exec < Arachni::Plugin::Base

    def prepare
        parsed_url = Arachni::URI( framework.options.url )

        @data          = {}
        @substitutions = {
            '__URL__'               => framework.options.url,
            '__URL_SCHEME__'        => parsed_url.scheme,
            '__URL_HOST__'          => parsed_url.host,
            '__URL_PORT__'          => parsed_url.port || 80,
            '__STAGE__'             => proc { @stage },
            '__ISSUE_COUNT__'       => proc do
                Arachni::Data.issues.size
            end,
            '__SITEMAP_SIZE__'      => proc do
                framework.data.sitemap.size
            end,
            '__FRAMEWORK_RUNTIME__' => proc do
                framework.statistics[:runtime]
            end,
            '__FRAMEWORK_STATUS__'  => proc do
                framework.status
            end
        }

        exec( :pre )
    end

    def run
        exec( :during )
    end

    def clean_up
        wait_while_framework_running
        exec( :post )

        register_results @data
    end

    def exec( stage )
        return if !options[stage]

        if defined?( Arachni::RPC::Server::Framework ) &&
            framework.is_a?( Arachni::RPC::Server::Framework )
            print_error 'Cannot be executed while running as an RPC server.'
            return
        end

        @stage = stage

        data = @data[stage.to_s] = {
            'status'     => nil,
            'pid'        => nil,
            'executable' => nil,
            'stdout'     => nil,
            'stderr'     => nil,
            'runtime'    => 0
        }

        executable          = options[stage.to_sym]
        expanded_executable = format( executable )

        print_status "Running #{stage} executable: #{expanded_executable}"

        data['executable'] = expanded_executable

        t = Time.now
        data['stdout'], data['stderr'], status =
            Open3.capture3( expanded_executable )

        data['runtime'] = Time.now - t

        data['status'] = status.exitstatus
        data['pid']    = status.pid

        print_info "Status: #{data['status']}"
        print_info "PID:    #{data['pid']}"
        print_info "STDOUT: #{data['stdout']}"
        print_info "STDERR: #{data['stderr']}"
    end

    def format( string )
        @substitutions.each do |variable, value|
            next if !string.include?( variable )

            value = value.call if value.respond_to? :call

            string = string.gsub( variable, value.to_s )
        end

        string
    end

    def self.info
        {
            name:        'Exec',
            description: %q{
Calls external executables at different scan stages.

The following variables can be used in the executable string:

* `__URL__`: Target URL.
* `__URL_SCHEME__`: URL scheme (http/https).
* `__URL_HOST__`: URL host.
* `__URL_PORT__`: URL port.
* `__STAGE__`: Scan stage (pre/during/post).
* `__ISSUE_COUNT__`: Amount of logged issues.
* `__SITEMAP_SIZE__`: Amount of discovered pages.
* `__FRAMEWORK_RUNTIME__`: Scan runtime.
* `__FRAMEWORK_STATUS__`: Framework status.

**Example:**

The following:

    echo "__URL__ __URL_SCHEME__ __URL_HOST__ __URL_PORT__ __STAGE__ __ISSUE_COUNT__ __SITEMAP_SIZE__ __FRAMEWORK_RUNTIME__ __FRAMEWORK_STATUS__"

Will result in:

    http://testfire.net/ http testfire.net 80 post 0 2 3.906482517 cleanup

_Will not work over RPC._
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1',
            options:     [
                Options::String.new( :pre,
                    description: 'Executable to be called prior to the scan.'
                ),
                Options::String.new( :during,
                    description: 'Executable to be called in parallel to the scan.'
                ),
                Options::String.new( :post,
                    description: 'Executable to be called after the scan.'
                )
            ]
        }
    end

end
