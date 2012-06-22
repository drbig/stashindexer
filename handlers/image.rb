#!/usr/bin/ruby1.9.1
#
# Stash Indexer, Images handler
#

require 'RMagick'

###
# Metadata model.
#
module STIN
  class Image
    include DataMapper::Resource

    property :id, Serial
    property :file, Integer, :required => true
    property :width, Integer
    property :height, Integer
    property :info, Text
  end
end

STIN.add_handler(/image\/.*/, 'STIN::Image') do |p,e|
  begin
    img = Magick::ImageList.new(p).first
  rescue Error => e
    STIN.log :error, "Image processor error at file #{p}!"
    STIN.log :error, 'Image details not added.'
    STIN.log :debug, e.backtrace.join("\n")
    STIN.log :debug, e.to_s
    nil
  else
    entry = STIN::Image.new(:file => e.id, :width => img.columns, :height => img.rows, \
                            :info => img.properties.collect{|k,v| "#{k} = #{v}"}.join("\n"))
    entry.save
    'STIN::Image'
  end
end
