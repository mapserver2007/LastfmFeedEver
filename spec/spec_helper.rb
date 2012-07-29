require 'rspec'
require 'yaml'
require File.dirname(__FILE__) + "/../lib/lastfmfeedever"
require File.dirname(__FILE__) + "/../lib/feed"
require File.dirname(__FILE__) + "/../lib/evernote"

module LastfmFeedEver
  class << self
    def evernote_config
      path = File.dirname(__FILE__) + "/../config/evernote.yml"
      YAML.load_file(path)
    end
    
    def evernote_auth
      path = File.dirname(__FILE__) + "/../config/evernote.auth.yml"
      YAML.load_file(path)["auth_token"]
    end

    def feed_config
      path = File.dirname(__FILE__) + "/../config/lastfm.yml"
      YAML.load_file(path)
    end
  end
end