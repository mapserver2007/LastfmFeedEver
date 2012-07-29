# -*- coding: utf-8 -*-
require 'yaml'
require 'feed'
require 'evernote'

module LastfmFeedEver
  VERSION = '0.0.2'
  
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
    
    # Evernote認証情報
    def evernote_auth_token
      path = File.dirname(__FILE__) + "/../config/evernote.auth.yml"
      load_config(path)
    end
    
    # 起動する
    def run
      feed = LastfmFeedEver::Feed.new(feed_user)
      evernote = LastfmFeedEver::MyEvernote.new(evernote_auth_token["auth_token"])
      # 前日の総合ランキングデータを取得する
      
      
      
      
      ["artist", "track"].each do |method|
        config = evernote_config[method]
        evernote.send("add_#{method}_note", feed.send(method), config["notebook"], config["tags"])
      end
    end
  end
end