#!/usr/bin/ruby1.9.1
#
# Stash Indexer, Documents handler
#

###
# Metadata model.
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
end

STIN.add_handler(/application\/pdf/, 'STIN::Document') do |p,e|
  begin
    info = `pdfinfo "#{p}" 2>/dev/null`
  rescue Exception => e
    STIN.log :error, "Document processor error at file #{p}!"
    STIN.log :error, 'Document details not added.'
    STIN.log :debug, e.backtrace.join("\n")
    STIN.log :debug, e.to_s
    nil
  else
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

    entry = STIN::Document.new(:file => e.id, :length => length, :title => title, \
                               :author => author, :info => info)
    entry.save
    'STIN::Document'
  end
end

