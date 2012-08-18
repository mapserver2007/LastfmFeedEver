# -*- coding: utf-8 -*-
$: << File.dirname(__FILE__) + "/evernote/lib"
$: << File.dirname(__FILE__) + "/evernote/lib/thrift"
$: << File.dirname(__FILE__) + "/evernote/lib/Evernote/EDAM"

require "thrift/types"
require "thrift/struct"
require "thrift/protocol/base_protocol"
require "thrift/protocol/binary_protocol"
require "thrift/transport/base_transport"
require "thrift/transport/http_client_transport"
require "Evernote/EDAM/user_store"
require "Evernote/EDAM/user_store_constants.rb"
require "Evernote/EDAM/note_store"
require "Evernote/EDAM/limits_constants.rb"
require "nokogiri"
require 'active_support'
require 'active_support/time'
require 'active_support/core_ext'

module LastfmFeedEver
  EVERNOTE_URL = "https://www.evernote.com/edam/user"
  RANK_SYMBOL_UP = '↑'
  RANK_SYMBOL_DOWN = '↓'
  RANK_SYMBOL_NO_CHANGE = '→'
  
  class MyEvernote
    def initialize(auth_token)
      @auth_token = auth_token
      userStoreTransport = Thrift::HTTPClientTransport.new(EVERNOTE_URL)
      userStoreProtocol = Thrift::BinaryProtocol.new(userStoreTransport)
      user_store = Evernote::EDAM::UserStore::UserStore::Client.new(userStoreProtocol)
      noteStoreUrl = user_store.getNoteStoreUrl(@auth_token)
      noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
      noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
      @note_store = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)
    end
    
    def add_artist_note(data, notebook, tags)
      @data = data
      @notebook = notebook
      @tags = tags
      @title = to_ascii(1.day.ago.strftime("%Y年%m月%d日") + "のベストアーティスト")
      add_note
    end
    
    def add_track_note(data, notebook, tags)
      @data = data
      @notebook = notebook
      @tags = tags
      @title = to_ascii(1.day.ago.strftime("%Y年%m月%d日") + "のベストトラック")
      add_note
    end
    
    # 2つのデータの差分を取る
    # base: 基準となるデータ
    # target: baseデータからの増減比較対象データ
    def add_diff(base, target)
      base.each do |key, value|
        unless target[key].nil?
          # 再生回数の差分
          base[key][:playcount_diff] = value[:playcount] - target[key][:playcount]
          # 順位の差分
          base[key][:rank_diff] = value[:rank] - target[key][:rank]
          # 前回順位
          base[key][:prev_rank] = target[key][:rank]
        else
          base[key][:playcount_diff] = nil
          base[key][:rank_diff] = nil
          base[key][:prev_rank] = nil
        end
      end
      base
    end
    
    # 前回のデータを取得する
    def get_note_in_prev(time, notebook, stack = nil, limit = 100)
      get_note(1.day.ago, notebook, stack, limit)
    end
    
    private
    def get_note(date, notebook, stack, limit)
      # 実際は翌日の深夜に実行するため、前日のデータを取得することになる
      notebook_guid = get_notebook_guid(notebook, stack)
      # 検索条件
      filter = Evernote::EDAM::NoteStore::NoteFilter.new
      filter.order = Evernote::EDAM::Type::NoteSortOrder::CREATED
      filter.notebookGuid = notebook_guid
      filter.timeZone = "Asia/Tokyo"
      filter.ascending = false # descending
      # ノート取得
      note_list = @note_store.findNotes(@auth_token, filter, 0, limit)
      daily_note = {}
      local_date = Time.local(date.year, date.month, date.day)
      
      hashmap = {}
      # 日付が一致しない場合は最新のデータを比較対象とする
      note = note_list.notes[0] 
      # 日付の一致したデータを取得
      note_list.notes.each do |note_|
        # 末尾3桁が0で埋まっているので除去する
        created_at = note.created.to_s
        unix_time = created_at.slice(0, created_at.length - 3)
        note_date = Time.at(unix_time.to_f)
        if note_date.strftime("%Y%m%d") == local_date.strftime("%Y%m%d")
          note = note_
          break
        end
      end
      
      content = @note_store.getNoteContent(@auth_token, note.guid)
      Nokogiri::XML(content).search("div").each do |elem|
        if /(\d+):\s(.*)\((\d+)\)/ =~ elem.text
          key = Digest::MD5.hexdigest($2)
          hashmap[key] = {
            :rank => $1.to_i,
            :title => $2,
            :playcount => $3.to_i
          }
        end
      end
      hashmap
    end
    
    def add_note
      note = Evernote::EDAM::Type::Note.new
      note.title = @title
      note.content = create_content(@data)
      note.notebookGuid  = get_notebook_guid(@notebook)
      note.tagGuids = get_tag_guid(@tags)
      @note_store.createNote(@auth_token, note)
    end
    
    def get_notebook_guid(notebook_name, stack_name = nil)
      notebook_name = to_ascii(notebook_name)
      stack_name = to_ascii(stack_name)
      @note_store.listNotebooks(@auth_token).each do |notebook|
        if notebook.name == notebook_name && 
          (stack_name == nil || notebook.stack == stack_name)
          return notebook.guid
        end
      end
    end
    
    def get_tag_guid(tag_list)
      tag_list.map!{|tag| to_ascii(tag)}
      @note_store.listTags(@auth_token).each_with_object [] do |tag, list|
        if tag_list.include? tag.name
          list << tag.guid
        end
      end
    end
    
    def create_content(list)
      # 再生回数が多い順に降順ソート
      list = list.sort_by {|k, v| v[:playcount] * -1}.inject [] do |daily_notes, note|
        daily_notes << note[1]
      end
      
      xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" + 
      "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml.dtd\">" +
      "<en-note>%s</en-note>"
      
      rank = same_rank_count = prev_playcount = 0
      xml % (list.each_with_object "" do |obj, html|
        text = nil
        if obj[:rank_diff].nil? || obj[:playcount_diff].nil? || obj[:prev_rank].nil?
          text = "#{obj[:title]}(#{obj[:playcount]})(new!)"
        else
          text = "#{obj[:title]}(#{obj[:playcount]})" +
                 "(再生回数:+#{obj[:playcount_diff]})" +
                 "(前回順位:#{(obj[:prev_rank])})" +
                 "(#{rank_symbol(obj[:rank_diff])})"
        end
        if obj[:playcount] != prev_playcount
          rank += same_rank_count + 1
          same_rank_count = 0
        else
          same_rank_count += 1
        end
        html << "<div><![CDATA[#{rank}: #{to_ascii(text)}]]></div>"
        prev_playcount = obj[:playcount]
      end)
    end
    
    def to_ascii(str)
      str.force_encoding("ASCII-8BIT") unless str.nil?
    end
    
    def rank_symbol(n)
      n = n.to_i
      if n < 0
        return RANK_SYMBOL_UP
      elsif n > 0
        return RANK_SYMBOL_DOWN
      else
        return RANK_SYMBOL_NO_CHANGE
      end
    end
  end
end

