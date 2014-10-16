require 'digest'

class Message
  include DataMapper::Resource
  
  property :id,           Serial
  property :body_hash,    String, :unique => true
  property :body,         Text
  property :analyzed,     Boolean, :default => false
  
  has n, :scans, :through => Resource
  has n, :patterns, :through => Resource
end

class Scan
  include DataMapper::Resource
  
  property :id,           Serial
  property :tag,          String
  property :active,       Boolean, :default => true
  property :created_at,   DateTime
  property :sensitivity,  Integer, :default => 1
  property :separator,    String
  
  has n,  :messages, :through => Resource
  has n,  :patterns
end

class Pattern
  include DataMapper::Resource
  
  property :id,           Serial
  property :body,         Text
  property :final,        Boolean, :default => false
  
  belongs_to :scan
  has n,  :messages, :through => Resource
end
