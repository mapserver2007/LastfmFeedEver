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
    
    # フィードを取得する
    def get_feed(kind)
      feed = LastfmFeedEver::Feed.new(feed_user)
      # データを加工
      hashmap = {}
      feed.send(kind).each_with_index do |obj, i|
        title = obj[:artist].nil? ? obj[:name] : obj[:name] + " - " + obj[:artist]
        key = Digest::MD5.hexdigest(title)
        hashmap[key] = {
          :rank => i + 1,
          :title => title,
          :playcount => obj[:playcount].to_i
        }
      end
      hashmap
    end
    
    # 起動する
    def run
      evernote = LastfmFeedEver::MyEvernote.new(evernote_auth_token["auth_token"])
      ["artist", "track"].each do |method|
        config = evernote_config[method]
        # 現在のデータを取得
        current_data = get_feed(method)
        # 前日のデータは24+設定時間
        # 0:00から+何時間で設定されているかを考慮
        hour = clock_time.split(":")[0].to_i + 1
        prev_data = evernote.get_note_in_prev(hour, config["notebook"])
        data = evernote.add_diff(current_data, prev_data)
        evernote.send("add_#{method}_note", data, config["notebook"], config["tags"])
      end
    end
  end
end