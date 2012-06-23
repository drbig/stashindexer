#!/usr/bin/ruby1.9.1
#
# Stash Indexer - Images handler
# by dRbiG
#

require 'RMagick'

module STIN
  class Image
    include DataMapper::Resource

    property :id, Serial
    property :file, Integer, :required => true
    property :width, Integer
    property :height, Integer
    property :info, Text
  end

  add_handler(/image\/.*/, 'STIN::Image') do |p,e|
    next false if e.mime.match(/.*djvu.*/) # early return, due to imagemagick segfaulting on djvu
    img = Magick::ImageList.new(p).first
    Image.new(:file => e.id, :width => img.columns, :height => img.rows, \
              :info => img.properties.collect{|k,v| "#{k} = #{v}"}.join("\n")).save
  end
end
