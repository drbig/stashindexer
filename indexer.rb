#!/usr/bin/ruby1.9.1
#
# Stash Indexer
# by dRbiG
#

VERSION = '0.0.1'

%w{ digest find logger pp optparse rubygems filemagic dm-core }.each{|g| require g}

###
# Basic database model.
# All main models are to be prefixed with 'St'.
# 
class Entry
  include DataMapper::Resource

  property :id, Serial
  property :digest, String, :required => true 
  property :name, String, :required => true
  property :path, String, :required => true
  property :size, Integer, :required => true
  property :mime, String
  property :mtime, DateTime
  property :ctime, DateTime

  has n, :tags, :through => Resource
end

class Tag
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
  property :ctime, DateTime, :default => Proc.new{|r,p| DateTime.now}

  has n, :entries, :through => Resource
end

DataMapper.finalize

###
# Command-line script starts here.
#
options = { :loglevel => 1, :database => File.join(Dir.pwd, 'data.bin'), :handlers => true, :root => false }
OptionParser.new do |o|
  o.banner = 'Usage: indexer.rb [options] tag1 dir1 tag2 dir2...'

  o.separator("\nAvailable options:")
  o.on('-v', '--verbose', 'Be more verbose.'){|a| options[:loglevel] = 0}
  o.on('-d', '--db PATH', 'Path to the SQLite database you want to use.') do |a|
    options[:database] = a
  end
  o.on('-n', '--no-handlers', 'Do not use file-specific handlers.'){options[:handlers] = false}
  o.on('-r', '--root PATH', 'Path to treat as dirs root.') do |a|
    unless File.exists? a and File.directory? a
      STDERR.puts "No such directory #{a}!"
      exit(5)
    end
    a += '/' unless a.end_with? '/'
    options[:root] = a
  end
  o.on_tail('--version', 'Show version and credits.') do
    puts "Stash Indexer v#{VERSION} by dRbiG."
    puts 'http://www.drbig.one.pl'
    exit
  end
end.parse!(ARGV)

if ARGV.length == 0 or ARGV.length % 2 != 0
  STDERR.puts \
"""You have to specify arguments: tag1 path1 (tag2 path2)...
Where pathX is a path you want to index, and tagX is the tag that will be assosicated with each file."""
  exit(5)
end

log = Logger.new(STDOUT)
log.formatter = proc{|s,d,p,m| "#{d.strftime('%H:%M:%S')} (#{s.ljust(5)}) #{m}\n"}
log.level = options[:loglevel]

DataMapper.setup(:default, 'sqlite://' + options[:database])
unless File.exists? options[:database]
  log.info 'Setting up fresh database...'
  require 'dm-migrations'
  DataMapper.auto_migrate!
end

fm = FileMagic.new(:mime)

Hash[*ARGV].each do |tag,path|
  unless File.exists? path
    log.warn "No such path #{path}!"
    log.warn "Skipping #{tag} #{path}."
    next
  end
  path += '/' unless path.end_with? '/'
  root = options[:root] || path
  unless path.start_with? root
    log.warn "Path #{path} is not located at root #{root}!"
    log.warn "Skipping #{tag} #{path}."
    next
  end
  unless t = Tag.first(:name => tag)
    t = Tag.new(:name => tag) 
    t.save
  end
  log.info "Walking #{path}..."
  Find.find(path) do |p|
    next unless File.file? p
    digest = Digest::MD5.file(p).hexdigest
    stat = File.stat(p)
    mime = fm.file(p).split(';').first
    path, name = File.split(p)
    path = '/' + (path.slice(root.length, path.length) || '')
    if e = Entry.first(:digest => digest)
      log.warn "Duplicate file #{name} (digest #{digest})"
      if e.name == name and e.path == path and e.tags.member?(t)
        log.warn 'Name, path and tag match, skipping.'
        next
      end
    end
    e = Entry.new(:name => name, :path => path, :digest => digest, :mime => mime, \
                  :size => stat.size, :mtime => stat.mtime, :ctime => stat.ctime)
    e.save
    EntryTag.new(:entry => e, :tag => t).save
  end
end
