# -*- coding: utf-8 -*-
$: << File.dirname(__FILE__) + "/../lib"
require 'lastfmfeedever'
require 'clockwork'
include Clockwork

schedule = LastfmFeedEver.clock_time
handler {|job| job.run }
every(1.day, LastfmFeedEver, :at => schedule)