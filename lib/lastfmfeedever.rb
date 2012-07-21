# -*- coding: utf-8 -*-
require 'yaml'
require 'feed'
require 'evernote'

module LastfmFeedEver
  VERSION = '0.0.1'
  
  class << self
    # 設定のロード
    def load_config(path)
      File.exists?(path) ? YAML.load_file(path) : ENV
    end
    
    # Last.fm UserId
    def feed_user
      path = File.dirname(__FILE__) + "/../config/lastfm.yml"
      load_config(path)["user_id"]
    end
    
    # clockwork実行時間設定
    def clock_time
      path = File.dirname(__FILE__) + "/../config/clock.yml"
      load_config(path)["schedule"]
    end
    
    # Evernote設定
    def evernote_config
      path = File.dirname(__FILE__) + "/../config/evernote.yml"
      load_config(path)
    end
    
    # 起動する
    def run
      feed = LastfmFeedEver::Feed.new(feed_user)
      evernote = LastfmFeedEver::MyEvernote.new(evernote_config["auth_token"])
      ["artist", "track"].each do |method|
        evernote.send("add_#{method}_note", feed.send(method),
          evernote_config["notebook"], evernote_config["#{method}_tags"])
      end
    end
  end
end