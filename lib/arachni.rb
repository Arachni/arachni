=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'rubygems'
require 'bundler/setup'

def ap( obj )
    super obj, raw: true
end

module Arachni
    # @return   [Bool]
    #   `true` if the `ARACHNI_PROFILE` env variable is set, `false` otherwise.
    def self.profile?
        !!ENV['ARACHNI_PROFILER']
    end
end

require_relative 'arachni/version'
require_relative 'arachni/banner'

# If there's no UI driving us then there's no output interface.
# Chances are that someone is using Arachni as a Ruby lib so there's no
# need for a functional output interface, so provide non-functional one.
#
# However, functional or not, the system does depend on one being available.
if !Arachni.constants.include?( :UI )
    require_relative 'arachni/ui/foo/output'
end

require_relative 'arachni/framework'
