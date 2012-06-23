#!/usr/bin/ruby1.9.1
#
# Stash Indexer - Basic model and handler framework
# by dRbiG
#

%w{ timeout rubygems dm-core }.each{|g| require g}

module STIN
  ###
  # Basic index model.
  #
  class File
    include DataMapper::Resource

    property :id, Serial
    property :name, String, :required => true
    property :path, String, :required => true
    property :size, Integer, :required => true
    property :stamp, DateTime, :default => Proc.new{|r,p| DateTime.now}
    property :mime, String
    property :digest, String
    property :mtime, DateTime
    property :ctime, DateTime
    property :additional, String

    has n, :tags, :through => Resource
  end

  class Tag
    include DataMapper::Resource

    property :id, Serial
    property :name, String, :required => true
    property :ctime, DateTime, :default => Proc.new{|r,p| DateTime.now}

    has n, :files, :through => Resource
  end

  ###
  # Handler framework.
  #
  @table = Array.new
  @map = Hash.new
  @logger = false
  @timeout = 10

  def self.logger=(obj); @logger = obj; end
  def self.timeout=(val); @timeout = val; end

  def self.log(level, msg)
    @logger.send(level, msg) if @logger
  end

  def self.add_handler(regexp, dataclass, &blk)
    @table.push([regexp, dataclass, blk])
    @map[dataclass.to_s] = dataclass
  end

  def self.process(path, entry)
    additional = Array.new
    @table.each do |h|
      regexp, dataclass, handler = h
      if entry.mime.match(regexp) or entry.name.match(regexp)
        ret = nil
        begin
          Timeout::timeout(@timeout){ret = handler.call(path, entry)}
        rescue Timeout::Error
          log :error, "#{dataclass.to_s} processor timeouted at file '#{path}'!"
          log :error, 'Additional details not saved.'
          log :debug, "Handler regexp: #{regexp.to_s}"
        rescue Interrupt
          log :error, "#{dataclass.to_s} processor interrupted at file '#{path}'!"
          log :error, 'Additional details not saved.'
          log :debug, "Handler regexp: #{regexp.to_s}"
        rescue Exception => e
          log :error, "#{dataclass.to_s} processor error at file '#{path}'!"
          log :error, 'Additional details not saved.'
          log :debug, "Handler regexp: #{regexp.to_s}"
          log :debug, e.backtrace.join("\n")
          log :debug, e.to_s
        else
          additional.push(dataclass.to_s) if ret
        end
      end
    end
    additional.uniq!
    if additional.length > 0
      entry.additional = additional.join(',')
      entry.save
    end
  end
end


