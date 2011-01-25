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
./bin/arachni http://demo.testfire.net --link-count=5
pprof.rb --gif /tmp/profile.dat > profile.gif
