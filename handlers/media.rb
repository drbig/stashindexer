#!/usr/bin/ruby1.9.1
#
# Stash Indexer - Media (Audio and Video) handler
# by dRbiG
#

module STIN
  class Video
    include DataMapper::Resource

    property :id, Serial
    property :file, Integer, :required => true
    property :length, Integer
    property :width, Integer
    property :height, Integer
    property :title, String
    property :info, Text
  end

  class Audio
    include DataMapper::Resource

    property :id, Serial
    property :file, Integer, :required => true
    property :length, Integer
    property :title, String
    property :artist, String
    property :album, String
    property :info, Text
  end 

  add_handler(/video\/.*/, 'STIN::Video') do |p,e|
    info = `ffprobe "#{p}" 2>&1`.match(/^Input .*/m)[0]
    width = height = length = title = nil
    if m = info.match(/(\d+)x(\d+)/)
      width = m[1]
      height = m[2]
    end
    if m = info.match(/^\s+(title|TITLE)\s+: (.*)$/)
      title = m[2]
    end
    if m = info.match(/^\s+Duration: (.*?),/)
      dur = m[1].split(':').collect(&:to_i)
      length = dur[0] * 3600 + dur[1] * 60 + dur[2]
    end
    Video.new(:file => e.id, :width => width, :height => height, \
              :length => length, :title => title, :info => info).save
  end

  add_handler(/audio\/.*/, 'STIN::Audio') do |p,e|
    info = `ffprobe "#{p}" 2>&1`.match(/^Input .*/m)[0]
    length = title = artist = album = nil
    if m = info.match(/^\s+(title|TITLE|TIT2)\s+: (.*)$/)
      title = m[2]
    end
    if m = info.match(/^\s+(artist|ARTIST|TPE1)\s+: (.*)$/)
      artist = m[2]
    end
    if m = info.match(/^\s+(album|ALBUM|TALB)\s+: (.*)$/)
      album = m[2]
    end
    if m = info.match(/^\s+Duration: (.*?),/)
      dur = m[1].split(':').collect(&:to_i)
      length = dur[0] * 3600 + dur[1] * 60 + dur[2]
    end
    Audio.new(:file => e.id, :length => length, :title => title, \
              :artist => artist, :album => album, :info => info).save
  end
end
