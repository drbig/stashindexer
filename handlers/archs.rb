#!/usr/bin/ruby1.9.1
#
# Stash Indexer - Archives handler
# by dRbiG
#

module STIN
  class Archive
    include DataMapper::Resource

    property :id, Serial
    property :file, Integer, :required => true
    property :info, Text
  end

  add_handler(/.*\.(tar\.gz|tgz)/, 'STIN::Archive') do |p,e|
    info = `tar --totals -tzf "#{p}" 2>&1`
    Archive.new(:file => e.id, :info => info).save
  end

  add_handler(/.*\.(tar\.(bz|bzip2)|tb(z|z2))/, 'STIN::Archive') do |p,e|
    info = `tar --totals -tjf "#{p}" 2>&1`
    Archive.new(:file => e.id, :info => info).save
  end

  add_handler(/.*\.zip/, 'STIN::Archive') do |p,e|
    info = `unzip -l "#{p}" 2>&1`
    Archive.new(:file => e.id, :info => info).save
  end

  add_handler(/.*\.rar/, 'STIN::Archive') do |p,e|
    info = `unrar l "#{p}" 2>&1`
    Archive.new(:file => e.id, :info => info).save
  end
end
