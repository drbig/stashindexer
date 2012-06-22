#!/usr/bin/ruby1.9.1
#
# Stash Indexer, Archive handler
#

###
# Metadata model.
#
module STIN
  class Archive
    include DataMapper::Resource

    property :id, Serial
    property :file, Integer, :required => true
    property :info, Text
  end
end

STIN.add_handler(/.*\.(tar\.gz|tgz)/, 'STIN::Archive') do |p,e|
  begin
    info = `tar --totals -tzf "#{p}"`
  rescue Error => e
    STIN.log :error, "Archive processor error at file #{p}!"
    STIN.log :error, 'Archive details not added.'
    STIN.log :debug, e.backtrace.join("\n")
    STIN.log :debug, e.to_s
    nil
  else
    entry = STIN::Archive.new(:file => e.id, :info => info)
    entry.save
    'STIN::Archive'
  end
end

STIN.add_handler(/.*\.(tar\.(bz|bzip2)|tb(z|z2))/, 'STIN::Archive') do |p,e|
  begin
    info = `tar --totals -tjf "#{p}"`
  rescue Error => e
    STIN.log :error, "Archive processor error at file #{p}!"
    STIN.log :error, 'Archive details not added.'
    STIN.log :debug, e.backtrace.join("\n")
    STIN.log :debug, e.to_s
    nil
  else
    entry = STIN::Archive.new(:file => e.id, :info => info)
    entry.save
    'STIN::Archive'
  end
end

STIN.add_handler(/.*\.zip/, 'STIN::Archive') do |p,e|
  begin
    info = `unzip -l "#{p}"`
  rescue Error => e
    STIN.log :error, "Archive processor error at file #{p}!"
    STIN.log :error, 'Archive details not added.'
    STIN.log :debug, e.backtrace.join("\n")
    STIN.log :debug, e.to_s
    nil
  else
    entry = STIN::Archive.new(:file => e.id, :info => info)
    entry.save
    'STIN::Archive'
  end
end

STIN.add_handler(/.*\.rar/, 'STIN::Archive') do |p,e|
  begin
    info = `unrar l "#{p}"`
  rescue Error => e
    STIN.log :error, "Archive processor error at file #{p}!"
    STIN.log :error, 'Archive details not added.'
    STIN.log :debug, e.backtrace.join("\n")
    STIN.log :debug, e.to_s
    nil
  else
    entry = STIN::Archive.new(:file => e.id, :info => info)
    entry.save
    'STIN::Archive'
  end
end
