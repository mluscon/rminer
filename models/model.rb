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
  property :packed,       Boolean, :default => true
  property :selected,     Boolean, :default => false

  has n,  :messages, :through => Resource
  has n,  :patterns

  belongs_to  :parent, :model => 'Pattern', :required => false
end

class Pattern
  include DataMapper::Resource

  property :id,           Serial
  property :body,         Text
  property :final,        Boolean, :default => false
  property :selected,     Boolean, :default => false
  property :final,        Boolean, :default => false
  property :packed,       Boolean, :default => true

  belongs_to :scan
  has n,     :messages, :through => Resource
  has n,     :childs, :model => 'Scan', :required => false, :through => Resource
end
