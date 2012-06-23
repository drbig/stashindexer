#!/usr/bin/ruby1.9.1
#
# Stash Indexer - Documents handler
# by dRbiG
#

module STIN
  class Document
    include DataMapper::Resource

    property :id, Serial
    property :file, Integer, :required => true
    property :length, Integer
    property :title, String
    property :author, String
    property :info, Text
  end

  add_handler(/application\/pdf/, 'STIN::Document') do |p,e|
    info = `pdfinfo "#{p}" 2>/dev/null`
    author = length = title = nil
    if m = info.match(/^Title:\s+(.*)$/)
      title = m[1]
    end
    if m = info.match(/^Author:\s+(.*)$/)
      author = m[1]
    end
    if m = info.match(/^Pages:\s+(.*)$/)
      length = m[1].to_i
    end
    Document.new(:file => e.id, :length => length, \
                 :title => title, :author => author, :info => info).save
  end
end

