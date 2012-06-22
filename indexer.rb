#!/usr/bin/ruby1.9.1
#
# Stash Indexer
# by dRbiG
#

VERSION = '0.0.1'

%w{ digest find logger pp optparse rubygems dm-core }.each{|g| require g}

options = { :loglevel => 1, :database => 'data.bin', :handlers => true, :root => false }
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

Hash[*ARGV].each do |tag,path|
  unless File.exists? path
    log.error "No such path #{path}!"
    log.error "Skipping #{tag} #{path}."
    next
  end
  path += '/' unless path.end_with? '/'
  root = options[:root] || path
  unless path.start_with? root
    log.error "Path #{path} is not located at root #{root}!"
    log.error "Skipping #{tag} #{path}."
    next
  end
  log.info "Walking #{path}..."
  Find.find(path) do |p|
    next unless File.file? p
    path, name = File.split(p)
    path = '/' + (path.slice(root.length, path.length) || '')
    puts "#{path.ljust(32)} #{name}"
  end
end
