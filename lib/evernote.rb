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
require 'active_support'

module LastfmFeedEver
  EVERNOTE_URL = "https://www.evernote.com/edam/user"
  
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
      @title = to_ascii(Time.now.strftime("%Y年%m月%d日") + "のベストアーティスト")
      add_note
    end
    
    def add_track_note(data, notebook, tags)
      @data = data
      @notebook = notebook
      @tags = tags
      @title = to_ascii(Time.now.strftime("%Y年%m月%d日") + "のベストトラック")
      add_note
    end
    
    private
    def add_note
      note = Evernote::EDAM::Type::Note.new
      note.title = @title
      note.content = create_content(@data)
      note.notebookGuid  = get_notebook_guid(@notebook)
      note.tagGuids = get_tag_guid(@tags)
      @note_store.createNote(@auth_token, note)
    end
    
    def to_ascii(str)
      str.force_encoding("ASCII-8BIT")
    end
    
    def get_notebook_guid(notebook_name)
      notebook_name = to_ascii(notebook_name)
      @note_store.listNotebooks(@auth_token).each do |notebook|
        if notebook.name == notebook_name
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
      xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" + 
      "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml.dtd\">" +
      "<en-note>%s</en-note>"
      rank = 1
      xml % (list.each_with_object "" do |obj, html|
        unless obj[:artist].nil?
          obj[:name] += " - " + obj[:artist]
        end
        html << "<div><![CDATA[#{rank}: #{to_ascii(obj[:name])}(#{obj[:playcount]})]]></div>"
        rank += 1
      end)
    end
  end
end

