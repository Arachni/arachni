=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'fileutils'
require 'tmpdir'

module Arachni::OptionGroups

# Holds paths to the directories of various system components.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Paths < Arachni::OptionGroup

    attr_accessor :root
    attr_accessor :arachni
    attr_accessor :gfx
    attr_accessor :components
    attr_accessor :logs
    attr_accessor :executables
    attr_accessor :checks
    attr_accessor :reporters
    attr_accessor :plugins
    attr_accessor :services
    attr_accessor :path_extractors
    attr_accessor :fingerprinters
    attr_accessor :lib
    attr_accessor :support
    attr_accessor :mixins
    attr_accessor :snapshots

    def initialize
        @root       = root_path
        @gfx        = @root + 'gfx/'
        @components = @root + 'components/'

        if self.class.config['framework']['snapshots']
            @snapshots  = self.class.config['framework']['snapshots']
        else
            @snapshots  = @root + 'snapshots/'
        end

        if ENV['ARACHNI_FRAMEWORK_LOGDIR']
            @logs = "#{ENV['ARACHNI_FRAMEWORK_LOGDIR']}/"
        elsif self.class.config['framework']['logs']
            @logs = self.class.config['framework']['logs']
        else
            @logs = "#{@root}logs/"
        end

        @checks          = @components + 'checks/'
        @reporters       = @components + 'reporters/'
        @plugins         = @components + 'plugins/'
        @services        = @components + 'services/'
        @path_extractors = @components + 'path_extractors/'
        @fingerprinters  = @components + 'fingerprinters/'

        @lib = @root + 'lib/arachni/'

        @executables = @lib + 'processes/executables/'
        @support     = @lib + 'support/'
        @mixins      = @support + 'mixins/'
        @arachni     = @lib[0...-1]
    end

    def root_path
        self.class.root_path
    end

    # @return   [String]    Root path of the framework.
    def self.root_path
        File.expand_path( File.dirname( __FILE__ ) + '/../../..' ) + '/'
    end

    def tmpdir
        if config['framework']['tmpdir'].to_s.empty?
            # On MS Windows Dir.tmpdir can return the path with a shortname,
            # better avoid that as it can be insonsistent with other paths.
            Arachni.get_long_win32_filename( Dir.tmpdir )
        else
            Arachni.get_long_win32_filename( config['framework']['tmpdir'] )
        end
    end

    def config
        self.class.config
    end

    def self.paths_config_file
        Arachni.get_long_win32_filename "#{root_path}config/write_paths.yml"
    end

    def self.clear_config_cache
        @config = nil
    end

    def self.config
        return @config if @config

        if !File.exist?( paths_config_file )
            @config = {}
        else
            @config = YAML.load( IO.read( paths_config_file ) )
        end

        @config['framework'] ||= {}
        @config['cli']       ||= {}

        @config.dup.each do |category, config|
            config.dup.each do |subcat, dir|
                if dir.to_s.empty?
                    @config[category].delete subcat
                    next
                end

                dir = Arachni.get_long_win32_filename( dir )

                if !Arachni.windows?
                    dir.gsub!( '~', ENV['HOME'] )
                end

                dir << '/' if !dir.end_with?( '/' )

                @config[category][subcat] = dir

                FileUtils.mkdir_p dir
            end
        end

        @config
    end

end
end
