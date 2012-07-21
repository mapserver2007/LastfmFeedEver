# -*- coding: utf-8 -*-
require 'nokogiri'
require 'open-uri'

module LastfmFeedEver
  class Feed
    ARTIST_FEED = "http://ws.audioscrobbler.com/2.0/user/%s/topartists.xml"
    TRACK_FEED = "http://ws.audioscrobbler.com/2.0/user/%s/toptracks.xml"
    
    def initialize(user_id)
      @artist_feed = ARTIST_FEED % user_id
      @track_feed = TRACK_FEED % user_id
    end
    
    def artist
      doc = Nokogiri::XML(open(@artist_feed))
      (doc/'//artist').inject [] do |list, elem|
        list << {
          :playcount => elem.at("playcount").text,
          :name => elem.at("name").text,
          :url => elem.at("url").text
        }
      end
    end

    def track
      doc = Nokogiri::XML(open(@track_feed))
      (doc/'//track').inject [] do |list, elem|
        list << {
          :playcount => elem.at("playcount").text,
          :name => elem.at("name").text,
          :artist => elem.search("artist/name").text,
          :url => elem.at("url").text
        }
      end
    end
  end
end