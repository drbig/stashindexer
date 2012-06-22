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
    img = Magick::ImageList.new(p).first
    entry = Image.new(:file => e.id, :width => img.columns, :height => img.rows, \
                      :info => img.properties.collect{|k,v| "#{k} = #{v}"}.join("\n"))
    entry.save
  end
end
