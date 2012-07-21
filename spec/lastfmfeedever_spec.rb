# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec/spec_helper')

describe LastfmFeedEver, 'が実行する処理' do
  before do
    @evernote_config = LastfmFeedEver.evernote_config
    @feed_config = LastfmFeedEver.feed_config
  end
  
  let(:feed) { LastfmFeedEver::Feed.new(@feed_config["user_id"]) }
  
  describe 'Last.fmのフィード取得処理' do
    it "アーティストのフィード情報が取得できること" do
      feed.artist.should_not be_empty
    end
    
    it "トラックのフィード情報が取得できること" do
      feed.track.should_not be_empty
    end
  end
  
  describe 'Evernoteへの投稿処理' do
    let(:evernote) { 
      LastfmFeedEver::MyEvernote.new(@evernote_config["auth_token"])
    }
    let(:notebook) { "Development" }
    let(:tags_artist) { @evernote_config["artist_tags"] }
    let(:tags_track) { @evernote_config["track_tags"] }
    
    it "アーティスト用タグへの登録が成功すること" do
      res = evernote.add_artist_note(feed.artist, notebook, tags_artist)
      # notebook: Development
      res.notebookGuid.should == "2c2b6d3a-9f5a-48a2-9a40-8d617cc556d7"
      # tag: Last.fm
      res.tagGuids[0].should == "e554deb8-7777-48db-afa0-9c76d06e6d33"
      # tag: LifeLog
      res.tagGuids[1].should == "f0a37dfa-d795-41fa-b68c-4b84373fae77"
      # tag: Last.fm - Artist
      res.tagGuids[2].should == "66eae836-717f-460d-9f26-831e3b38935c"
    end
    
    it "トラック用タグへの登録が成功すること" do
      res = evernote.add_track_note(feed.track, notebook, tags_track)
      # notebook: Development
      res.notebookGuid.should == "2c2b6d3a-9f5a-48a2-9a40-8d617cc556d7"
      # tag: Last.fm
      res.tagGuids[0].should == "e554deb8-7777-48db-afa0-9c76d06e6d33"
      # tag: LifeLog
      res.tagGuids[1].should == "f0a37dfa-d795-41fa-b68c-4b84373fae77"
      # tag: Last.fm - Track
      res.tagGuids[2].should == "8ffc2c9f-00d3-45fb-866d-62eac2d83ec5"
    end
  end
end