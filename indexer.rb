#!/usr/bin/ruby1.9.1
#
# Stash Indexer - Indexer
# by dRbiG
#

VERSION = '0.0.2'

%w{ digest find logger pp optparse rubygems filemagic dm-core progressbar ./stin.rb }.each{|g| require g}

###
# Command-line script starts here.
#
options = { :loglevel => 1, :database => File.join(Dir.pwd, 'data.bin'), \
            :handlers => true, :root => false, :digest => true, :tags => false }
OptionParser.new do |o|
  o.banner = 'Usage: indexer.rb [options] tag1 dir1 tag2 dir2...'

  o.separator("\nAvailable options:")
  o.on('-v', '--verbose', 'Be more verbose.'){|a| options[:loglevel] = 0}
  o.on('-i', '--index PATH', 'Path to the SQLite database you want to use.') do |a| 
    options[:database] = File.absolute_path(a)
  end
  o.on('-d', '--no-digest', 'Turn off MD5 digests (has consequences!).'){options[:digest] = false}
  o.on('-s', '--no-handlers', 'Do not use filetype-specific handlers.'){options[:handlers] = false}
  o.on('-t', '--tag name,...', Array, 'Use additional tags for all paths.'){|a| options[:tags] = a}
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
STIN.logger = log

if options[:handlers]
  Dir.open(File.join(Dir.pwd, 'handlers')).each do |p|
    next if File.extname(p) != '.rb'
    load File.join(Dir.pwd, 'handlers', p)
  end
end

DataMapper.finalize
DataMapper.setup(:default, 'sqlite://' + options[:database])
unless File.exists? options[:database]
  log.info 'Setting up fresh database...'
  require 'dm-migrations'
  DataMapper.auto_migrate!
end

fm = FileMagic.new(:mime_type)

tags = Array.new
if options[:tags]
  options[:tags].each do |n|
    unless t = STIN::Tag.first(:name => n)
      t = STIN::Tag.new(:name => n)
      t.save
    end
    tags.push(t)
  end
end

log.warn 'Running without MD5 digests!' unless options[:digest]
Hash[*ARGV].each do |tag,path|
  log.info "Running loop for tag #{tag}."
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
  unless t = STIN::Tag.first(:name => tag)
    t = STIN::Tag.new(:name => tag) 
    t.save
  end
  tags.push(t)
  log.info "Walking #{path}..."
  filetree = Array.new
  Find.find(path) do |p|
    next unless File.file? p
    filetree << p
  end
  pbar = ProgressBar.new('Processing', filetree.length)
  filetree.each do |p|
    pbar.inc
    path, name = File.split(p)
    path = '/' + (path.slice(root.length, path.length) || '')
    begin
      digest = options[:digest] ? Digest::MD5.file(p).hexdigest : nil
      stat = File.stat(p)
      mime = fm.file(p)
    rescue IOError => e
      log.error "IOError at file #{name}!"
      log.error 'Skipping.'
      next
    end
    if options[:digest]
      es = STIN::File.all(:digest => digest)
    else
      es = STIN::File.all(:name => name)
    end
    if es and es.length > 0
      log.warn "Duplicate file #{name}"
      skip = false
      es.each do |e|
        if e.name == name and e.path == path and e.tags.member?(t)
          log.warn 'Name, path and tag match, skipping.'
          skip = true
          break
        end
      end
      next if skip
    end
    e = STIN::File.new(:name => name, :path => path, :size => stat.size, :mime => mime, \
                       :digest => digest, :mtime => stat.mtime, :ctime => stat.ctime)
    e.save
    tags.each do |t|
      STIN::FileTag.new(:file => e, :tag => t).save
    end
    STIN.process(p, e) if options[:handlers]
  end
  pbar.finish
  tags.pop
end
