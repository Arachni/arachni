#!/bin/sh
#
# Simple profiler using perftools[1].
#
# To install perftools for Ruby:
#   sudo gem install perftools.rb
#
# [1] https://github.com/tmm1/perftools.rb
#
CPUPROFILE_FREQUENCY=500 CPUPROFILE=/tmp/profile.dat RUBYOPT="-r`gem which perftools | tail -1`" \
ruby arachni.rb http://demo.testfire.net --link-count=5 --report=html --plugin=cookie_collector --plugin=healthmap --plugin=content_types
pprof.rb --gif /tmp/profile.dat > profile.gif
